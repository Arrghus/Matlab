function [L2norm,v,mov] = simple2D(boundType,stepType,testType,N)

%%%%% Setup
% boundType = 0; %0=Neumann, 1=Dirichlet
% stepType = 0;  %0=RK4, 1=mod. eq. method
%N = 100;
%CFL = 0;
    
    movTime = 2;
    eigTest=0;
    L2Test=0;
    errTest=0;
    tEnd = 2*pi;
    switch testType
      case 1
        eigTest=1;
      case 2
        L2Test=1;
        tEnd=1;
      case 3
        errTest=1;
      case 4
        movTime=0;
      case 5
        tEnd=pi/5;
        movTime=0;
    end
    
    [u_x,v_x,u_y,v_y] = u_vars();
    u_t = sqrt(u_x^2+u_y^2);
    
    function out = f(x,y,t)
        out = kron(sin(u_x*x+v_x),sin(u_y*y+v_y))*cos(u_t*t);
    end
    function out = f_x(x,y,t)
        out = kron(u_x*cos(u_x*x+v_x),sin(u_y*y+v_y))*cos(u_t*t);
    end
    function out = f_y(x,y,t)
        out = kron(sin(u_x*x+v_x),u_y*cos(u_y*y+v_y))*cos(u_t*t);
    end
    function out = f_t(x,y,t)
        out = kron(sin(u_x*x+v_x),sin(u_y*y+v_y))*-u_t*sin(u_t*t);
    end
    
    CFL = 30;  %Quick-n-dirty CFL-numbers. Probably won't work if
               %b,c ~= 1
    movN = movTime*30;

    t = 0;
    
    xmin = 0;
    xmax = pi;

    ymin = 0;
    ymax = pi;

    x = linspace(xmin,xmax, N+1)';
    y = linspace(ymin,ymax, N+1)';
    h = x(2)-x(1);
    
    dt = h/CFL;
    M = ceil(tEnd/dt);
    dt = tEnd/M;

    v = 0;
    v_prev = 0;
    if stepType==0
        v = [f(x,y,t); f_t(x,y,t)];
    end
    if stepType==1
        v = f(x,y,t);
        v_prev = f(x,y,t-dt);
    end
    
    function out = b(x)
        out = ones(size(x));
    end

    function out = c(y)
        out = ones(size(y));
    end
    
    function out = N_g0(y,t)
        out = f_x(xmin,y,t);
    end
    function out = N_g1(y,t)
        out = f_x(xmax,y,t);
    end
    function out = N_g2(x,t)
        out = f_y(x,ymin,t);
    end
    function out = N_g3(x,t)
        out = f_y(x,ymax,t);
    end
    
    function out = D_g0(y,t) 
        out = f(xmin,y,t);
    end
    function out = D_g1(y,t)
        out = f(xmax,y,t);
    end
    function out = D_g2(x,t)
        out = f(x,ymin,t);
        %out = sin(4*x+3)+sin(2)*cos(5*t);
    end
    function out = D_g3(x,t)
        out = f(x,ymax,t);
        %out = sin(4*x+3)+sin(3*pi+2)*cos(5*t);
    end
    
    if boundType==0
        g0 = @N_g0;
        g1 = @N_g1;
        g2 = @N_g2;
        g3 = @N_g3;
    end
    
    if boundType==1
        g0 = @D_g0;
        g1 = @D_g1;
        g2 = @D_g2;
        g3 = @D_g3;
    end
    
    bigN = (N+1)^2;
    
    mov = zeros(bigN,movN);
    movDt = tEnd/movN;
    
    gamma = 5; %Dirichlet tuning variable

    %%%%% Operator creation
    %alph = 0.2508560249; %For fourth-order operators
    alph = 0.1878715026;  %For sixth-order operators
    I = sparse(eye(N+1));
    deriv = @HOM6_D_VAR_NARROW;
    [HI,~,D2x,BSx] = deriv(N+1,h,b(x));
    [~,~,D2y,BSy] = deriv(N+1,h,c(y));
    % [H,~,D2,BS] = SBP8(N+1,h);
    % HI = inv(H);
    HI = sparse(HI);
    e0 = sparse(  1,1,1,N+1,1);
    eN = sparse(N+1,1,1,N+1,1);
    He0 = HI*e0;
    HeN = HI*eN;
    
    bigD2x = kron(D2x,I);
    bigD2y = kron(I,D2y);
    
    if boundType==0
        SATx = kron(-1*HI*BSx,I);
        SATy = kron(I,-1*HI*BSy);
        bigD = bigD2x+SATx+bigD2y+SATy;
    end
    
    function S = Neum(int_t)
        S0 = kron(He0,g0(y,int_t));
        S1 = kron(HeN,g1(y,int_t));
        S2 = kron(g2(x,int_t),He0);
        S3 = kron(g3(x,int_t),HeN);
        
        S = S0 - S1 + S2 - S3;
    end

    tau = -gamma/(alph*h);
    if boundType==1
        SATx =        kron(BSx'       *(e0*e0'),I);
        SATx = SATx + kron(tau*b(xmin)*(e0*e0'),I);
        SATx = SATx + kron(BSx'       *(eN*eN'),I);
        SATx = SATx + kron(tau*b(xmax)*(eN*eN'),I);
        SATx = kron(HI,I)*SATx;
        
        SATy =        kron(I,BSy'       *(e0*e0'));
        SATy = SATy + kron(I,tau*c(ymin)*(e0*e0'));
        SATy = SATy + kron(I,BSy'       *(eN*eN'));
        SATy = SATy + kron(I,tau*c(ymax)*(eN*eN'));
        SATy = kron(I,HI)*SATy;
        
        bigD = bigD2x+SATx+bigD2y+SATy;
    end
    
    function S = Diri(int_t)
        xlow  = g0(y,int_t);
        xhigh = g1(y,int_t);
        S0x = kron(BSx'       *e0,xlow );
        S1x = kron(tau*b(xmin)*e0,xlow );
        S2x = kron(BSx'       *eN,xhigh);
        S3x = kron(tau*b(xmax)*eN,xhigh);
        
        Sx = kron(HI,I)*(S0x + S1x + S2x + S3x);
        
        ylow  = g2(x,int_t);
        yhigh = g3(x,int_t);
        S0y = kron(ylow ,BSy'       *e0);
        S1y = kron(ylow ,tau*c(ymin)*e0);
        S2y = kron(yhigh,BSy'       *eN);
        S3y = kron(yhigh,tau*c(ymax)*eN);
        
        Sy = kron(I,HI)*(S0y + S1y + S2y + S3y);
        S = Sx+Sy;
    end

    
    if eigTest
        val = (eig(full(bigD)));
        plot(real(val),imag(val),'*');
        return;
    end
    
    if stepType==0
        big0 = sparse(bigN,bigN);
        bigI = kron(I,I);
        bigD = [big0 bigI; bigD big0];
        Nl = sparse(bigN,1);
    end
    
    function out = prim0(in,t)
        S = Neum(t);
        S = [Nl; S];
        out = bigD*in-S;
    end
    function out = bis0(in,t,dtSq)
        S = Neum(t);
        S_tt = -u_t^2*S;
        out = bigD*(in+dtSq/12*(bigD*in-S))-S-S_tt*dtSq/12;
    end
    function out = prim1(in,t)
        S = Diri(t);
        S = [Nl; S];
        out = bigD*in-S;
    end
    function out = bis1(in,t,dtSq)
        S = Diri(t);
        S_tt = -u_t^2*S;
        out = bigD*(in+dtSq/12*(bigD*in-S))-S-S_tt*dtSq/12;
    end

    if boundType==0
        prim = @prim0;
    end
    if boundType==1
        prim = @prim1;
    end
    if boundType==0
        bis = @bis0;
    end
    if boundType==1
        bis = @bis1;
    end
    
    %%%%% Looping
    if stepType==0
        [v,mov,movTArr] = primStep(v,dt,M,prim,t,mov,movDt,bigN);
    end
    if stepType==1
        [v,mov,movTArr] = bisStep(v,v_prev,dt,M,bis,t,mov,movDt,bigN);
    end
    
    %%%%%%% Printing
    if L2Test
        movL2 = zeros(1,movN);
        for ii = 1:movN
            movL2(ii) = L2(mov(:,ii),f(x,y,movTArr(ii)),h);
        end
        plot(linspace(0,tEnd,movN),movL2);
    end
    
    if movN && not(L2Test)
        if errTest
            for ii = 1:movN
                mov(:,ii) = mov(:,ii)-f(x,y,movTArr(ii));
            end
        end
        
        movMax = max(max(mov));
        movMin = min(min(mov));
        trueMov = zeros(N+1);
        for ii = 1:movN
            pause(movTime/movN);
            frame = reshape(mov(:,ii),[N+1 N+1]);
            surf(x,y,frame);
            axis([xmin xmax ymin ymax movMin movMax]);
            caxis([movMin movMax]);
        end
    end
    
    L2norm = L2(v,f(x,y,tEnd),h);
end