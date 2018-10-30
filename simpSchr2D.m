function [L2norm,v,mov] = simpSchr2D(testType,N)

%%%%% Setup
% boundType = 0; %0=Neumann, 1=Dirichlet
% stepType = 0;  %0=RK4, 1=mod. eq. method
%N = 100;
%CFL = 0;
    
    stepType = 0;
    boundType = 0;
    movTime = 2;
    eigTest=0;
    L2Test=0;
    errTest=0;
    tEnd = 0.01*pi;
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
    
    u_x = 4;
    v_x = 5;
    u_y = 3;
    v_y = 2;
    u_t = i*(u_x^2+u_y^2);
    
    function out = f(x,y,t)
        out = kron(sin(u_x*x+v_x),sin(u_y*y+v_y))*exp(u_t*t);
    end
    function out = f_x(x,y,t)
        out = kron(u_x*cos(u_x*x+v_x),sin(u_y*y+v_y))*exp(u_t*t);
    end
    function out = f_y(x,y,t)
        out = kron(sin(u_x*x+v_x),u_y*cos(u_y*y+v_y))*exp(u_t*t);
    end
    function out = f_t(x,y,t)
        out = kron(sin(u_x*x+v_x),sin(u_y*y+v_y))*u_t*exp(u_t*t);
    end
    
    CFL = 100;  %Quick-n-dirty CFL-numbers. Probably won't work if
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
        v = f(x,y,t);
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
    
    %%%%% Operator creation
    I = sparse(eye(N+1));
    [HI,~,D2x,BSx] = HOM6_D_VAR_NARROW(N+1,h,b(x));
    [~,~,D2y,BSy] = HOM6_D_VAR_NARROW(N+1,h,c(y));
    % [H,~,D2,BS] = SBP8(N+1,h);
    % HI = inv(H);
    HI = sparse(HI);
    e0 = sparse(  1,1,1,N+1,1);
    eN = sparse(N+1,1,1,N+1,1);
    He0 = HI*e0;
    HeN = HI*eN;
    
    bigD2x = -i*kron(D2x,I);
    bigD2y = -i*kron(I,D2y);
    
    if boundType==0
        SATx = kron(1i*HI*BSx',I);
        SATy = kron(I,1i*HI*BSy');
        bigD = bigD2x+SATx+bigD2y+SATy;
    end
    
    function S = Neum(int_t)
        S0 = kron(He0,g0(y,int_t));
        S1 = kron(HeN,g1(y,int_t));
        S2 = kron(g2(x,int_t),He0);
        S3 = kron(g3(x,int_t),HeN);
        
        S = 0*(S0 - S1 + S2 - S3);
    end

    if eigTest
        val = (eig(full(bigD)));
        plot(real(val),imag(val),'*');
        return;
    end
    
    function out = prim0(in,t)
        S = Neum(t);
        out = bigD*in-S;
    end

    prim = @prim0;
    
    %%%%% Looping
    [v,mov,movTArr] = primStep(v,dt,M,prim,t,mov,movDt,bigN);

    mov = real(mov);
    
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