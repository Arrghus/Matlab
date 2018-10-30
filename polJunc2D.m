function [L2norm,v,mov] = polJunc2D(boundType,stepType,testType,NL)
    
%%%%% Setup
% boundType = 0; %0=Neumann, 1=Dirichlet
% stepType = 0;  %0=RK4, 1=2nd order stepping
    
    movTime = 2;
    L2Test=0;
    eigTest=0;
    errTest=0;
    tEnd = 2*pi;
    deriv = @HOM4_D_VAR_NARROW;
    junction = @Junction_4;
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
    
    %Based on assumptions within interpolation generator.
    if mod(NL,2)==1
        error('NL must be divisible by two');
    end
    ND = NL/2;
    NU = NL/2;
    
    CFL = 30;  %Quick-n-dirty CFL-numbers. Probably won't work if
               %b,c ~= 1
    movN = movTime*30;

    t = 0;

    xmin = 0;
    xmid = pi;
    xmax = 2*pi;

    ymin = 0;
    ymid = pi;
    ymax = 2*pi;

    xL = linspace(xmin,xmid, NL+1)';
    xD = linspace(xmid,xmax, ND+1)';
    xU = linspace(xmid,xmax, NU+1)';
    yL = linspace(ymin,ymax, 2*NL+1)';
    yD = linspace(ymin,ymid, ND+1)';
    yU = linspace(ymid,ymax, NU+1)';
    hL = xL(2)-xL(1);
    hD = xD(2)-xD(1);
    hU = xU(2)-xU(1);
    
    dt = min([hL hD hU])/CFL;
    M = ceil(tEnd/dt);
    dt = tEnd/M;
    
    v = 0;
    if stepType==0
        v = [f(xL,yL,t); f(xD,yD,t); f(xU,yU,t); ...
             f_t(xL,yL,t); f_t(xD,yD,t); f_t(xU,yU,t)];
    end
    if stepType==1
        v =      [f(xL,yL,t   ); f(xD,yD,t   ); f(xU,yU,t   )];
        v_prev = [f(xL,yL,t-dt); f(xD,yD,t-dt); f(xU,yU,t-dt)];
    end
    
    function out = bL(x)
        out = ones(size(x));
    end
    function out = bD(x)
        out = ones(size(x));
    end
    function out = bU(x)
        out = ones(size(x));
    end
    function out = cL(y)
        out = ones(size(y));
    end
    function out = cD(y)
        out = ones(size(y));
    end
    function out = cU(y)
        out = ones(size(y));
    end
    
    %%Autogenerated boundaries
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
    end
    function out = D_g3(x,t)
        out = f(x,ymax,t);
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
    
    bigNL = (NL+1)*(2*NL+1);
    bigND = (ND+1)^2;
    bigNU = (NU+1)^2;
    bigbigN = bigNL+bigND+bigNU;
    
    mov = zeros(bigbigN,movN);
    movDt = tEnd/movN;
    
    gamma = 5; %Dirichlet tuning variable

    %%%%% Operator creation
    %alph = 0.2508560249; %For fourth-order operators
    alph = 0.1878715026;  %For sixth-order operators
    IxL = sparse(eye(  NL+1));
    IyL = sparse(eye(2*NL+1));
    ID  = sparse(eye(  ND+1));
    IU  = sparse(eye(  NU+1));
    [HIxL,~,D2xL,BSxL] = deriv(  NL+1,hL,bL(xL));
    [HID ,~,D2xD,BSxD] = deriv(  ND+1,hD,bD(xD));
    [HIU ,~,D2xU,BSxU] = deriv(  NU+1,hU,bU(xU));
    [HIyL,~,D2yL,BSyL] = deriv(2*NL+1,hL,cL(yL));
    [~   ,~,D2yD,BSyD] = deriv(  ND+1,hD,cD(yD));
    [~   ,~,D2yU,BSyU] = deriv(  NU+1,hU,cU(yU));
    % [H,~,D2,BS] = SBP8(N+1,h);
    % HI = inv(H);
    HIxL = sparse(HIxL);
    HIyL = sparse(HIyL);
    HID = sparse(HID);
    HIU = sparse(HIU);

    e0xL = sparse(  1,1,1,  NL+1,1);
    e0yL = sparse(  1,1,1,2*NL+1,1);
    e0D  = sparse(  1,1,1,  ND+1,1);
    e0U  = sparse(  1,1,1,  NU+1,1);
    
    eNxL = sparse(  NL+1,1,1,  NL+1,1);
    eNyL = sparse(2*NL+1,1,1,2*NL+1,1);
    eND  = sparse(  ND+1,1,1,  ND+1,1);
    eNU  = sparse(  NU+1,1,1,  NU+1,1);

    He0xL = HIxL*e0xL;
    He0yL = HIyL*e0yL;
    He0D  = HID *e0D;
    %He0U = HIU*e0U;
    
    %HeNxL = HIxL*eNxL;
    HeNyL = HIyL*eNyL;
    HeND  = HID *eND;
    HeNU  = HIU *eNU;
    
    big0LL = sparse(bigNL,bigNL);
    big0LR = sparse(bigNL,bigND+bigNU);
    big0RL = sparse(bigND+bigNU,bigNL);
    big0DU = sparse(bigND,bigNU);
    big0UD = sparse(bigNU,bigND);

    %Extra pieces for prim1 and bis1
    bigHIxL = kron(HIxL,IyL);
    bigHIxD = kron(HID,ID);
    bigHIxU = kron(HIU,IU);
    bigbigHIx = [bigHIxL big0LR; big0RL [bigHIxD big0DU; big0UD bigHIxU]];
    bigHIyL = kron(IxL,HIyL);
    bigHIyD = kron(ID,HID);
    bigHIyU = kron(IU,HIU);
    bigbigHIy = [bigHIyL big0LR; big0RL [bigHIyD big0DU; big0UD bigHIyU]];

    bigD2xL = kron(D2xL,IyL);
    bigD2xD = kron(D2xD,ID);
    bigD2xU = kron(D2xU,IU);
    bigD2yL = kron(IxL,D2yL);
    bigD2yD = kron(ID,D2yD);
    bigD2yU = kron(IU,D2yU);
    
    if boundType==0
        SATxL = kron(-1*HIxL*(e0xL*e0xL')*BSxL,IyL);
        SATxD = kron(-1*HID*(eND*eND')*BSxD,ID);
        SATxU = kron(-1*HIU*(eNU*eNU')*BSxU,IU);
        SATyL = kron(IxL,-1*HIyL*BSyL);
        SATyD = kron(ID,-1*HID*(e0D*e0D')*BSyD);
        SATyU = kron(IU,-1*HIU*(eNU*eNU')*BSyU);
        bigDL = bigD2xL+SATxL+bigD2yL+SATyL;
        bigDD = bigD2xD+SATxD+bigD2yD+SATyD;
        bigDU = bigD2xU+SATxU+bigD2yU+SATyU;
        bigD = [bigDL big0LR; big0RL [bigDD big0DU; big0UD bigDU]];
    end

    function S = Neum(t)
        S0 = kron(He0xL,g0(yL,t));
        S1D = kron(HeND,g1(yD,t));
        S1U = kron(HeNU,g1(yU,t));
        S2L = kron(g2(xL,t),He0yL);
        S2D = kron(g2(xD,t),He0D);
        S3L = kron(g3(xL,t),HeNyL);
        S3U = kron(g3(xU,t),HeNU);
        
        S = [S0+S2L-S3L; -S1D+S2D; -S1U-S3U];
    end        
    
    tauL = -gamma/(alph*hL);
    tauD = -gamma/(alph*hD);
    tauU = -gamma/(alph*hU);
    if boundType==1
        SATxL =         kron(BSxL'       *(e0xL*e0xL'),IyL);
        SATxL = SATxL + kron(tauL*bL(xmin)*(e0xL*e0xL'),IyL);
        SATxL = bigHIxL*SATxL;

        SATxD =         kron(BSxD'       *(eND*eND'),ID);
        SATxD = SATxD + kron(tauD*bD(xmax)*(eND*eND'),ID);
        SATxD = bigHIxD*SATxD;
        
        SATxU =         kron(BSxU'       *(eNU*eNU'),IU);
        SATxU = SATxU + kron(tauU*bU(xmax)*(eNU*eNU'),IU);
        SATxU = bigHIxU*SATxU;
        
        SATyL =         kron(IxL,BSyL'        *(e0yL*e0yL'));
        SATyL = SATyL + kron(IxL,tauL*cL(ymin)*(e0yL*e0yL'));
        SATyL = SATyL + kron(IxL,BSyL'        *(eNyL*eNyL'));
        SATyL = SATyL + kron(IxL,tauL*cL(ymax)*(eNyL*eNyL'));
        SATyL = bigHIyL*SATyL;

        SATyD =         kron(ID,BSyD'        *(e0D*e0D'));
        SATyD = SATyD + kron(ID,tauD*cD(ymin)*(e0D*e0D'));
        SATyD = bigHIyD*SATyD;
       
        SATyU =         kron(IU,BSyU'        *(eNU*eNU'));
        SATyU = SATyU + kron(IU,tauU*cU(ymax)*(eNU*eNU'));
        SATyU = bigHIyU*SATyU;
       
        bigDL = bigD2xL+SATxL+bigD2yL+SATyL;
        bigDD = bigD2xD+SATxD+bigD2yD+SATyD;
        bigDU = bigD2xU+SATxU+bigD2yU+SATyU;
        bigD = [bigDL big0LR; big0RL [bigDD big0DU; big0UD bigDU]];
    end

    function S = Diri(t)
        xlow  = g0(yL,t);
        xhighD = g1(yD,t);
        xhighU = g1(yU,t);
        S0xL = kron(BSxL'       *e0xL,xlow );
        S1xL = kron(tauL*bL(xmin)*e0xL,xlow );
        S2xD = kron(BSxD'       *eND,xhighD);
        S3xD = kron(tauD*bD(xmax)*eND,xhighD);
        S2xU = kron(BSxU'       *eNU,xhighU);
        S3xU = kron(tauU*bU(xmax)*eNU,xhighU);
        
        Sx = bigbigHIx*[S0xL+S1xL; S2xD+S3xD; S2xU+S3xU];
        
        ylowL  = g2(xL,t);
        yhighL = g3(xL,t);
        S0yL = kron(ylowL ,BSyL'       *e0yL);
        S1yL = kron(ylowL ,tauL*cL(ymin)*e0yL);
        S2yL = kron(yhighL,BSyL'       *eNyL);
        S3yL = kron(yhighL,tauL*cL(ymax)*eNyL);
        SyL = S0yL+S1yL+S2yL+S3yL;
        
        ylow  = g2(xD,t);
        yhigh = g3(xU,t);
        S0yD = kron(ylow ,BSyD'       *e0D);
        S1yD = kron(ylow ,tauD*cD(ymin)*e0D);
        S2yU = kron(yhigh,BSyU'       *eNU);
        S3yU = kron(yhigh,tauU*cU(ymax)*eNU);
        SyD = S0yD+S1yD;
        SyU = S2yU+S3yU;
        
        Sy = bigbigHIy*[SyL; SyD; SyU];
        S = Sx+Sy;
    end        
    
    %%Insert grid interface D-U
    % [polDU,polUD] = Interpolation_4(NU+1);
    % polDU = sparse(polDU);
    % polUD = sparse(polUD);
    
    polDU = sparse(eye(ND+1));
    polUD = sparse(eye(NU+1));

    tau_i   = -5*(cD(ymid)+cU(ymid))/(4*alph*min([hD hU]));
    beta_i  = 0.5;
    gamma_i = -0.5;
    
    interDD =         + kron(ID,tau_i  *HID      *(eND*eND')     );
    interDD = interDD + kron(ID,beta_i *HID*BSyD'*(eND*eND')     );
    interDD = interDD + kron(ID,gamma_i*HID      *(eND*eND')*BSyD);
    
    interDU =         + kron(polDU,tau_i  *HID      *(eND*-e0U')     );
    interDU = interDU + kron(polDU,beta_i *HID*BSyD'*(eND*-e0U')     );
    interDU = interDU + kron(polDU,gamma_i*HID      *(eND* e0U')*BSyU);
    
    interUD =         - kron(polUD,tau_i  *HIU      *(e0U*eND')     );
    interUD = interUD - kron(polUD,beta_i *HIU*BSyU'*(e0U*eND')     );
    interUD = interUD + kron(polUD,gamma_i*HIU      *(e0U*eND')*BSyD);
    
    interUU =         - kron(IU,tau_i  *HIU      *(e0U*-e0U')     );
    interUU = interUU - kron(IU,beta_i *HIU*BSyU'*(e0U*-e0U')     );
    interUU = interUU + kron(IU,gamma_i*HIU      *(e0U* e0U')*BSyU);
    
    bigD = bigD + [big0LL big0LR; big0RL [interDD interDU; interUD ...
                        interUU]];
    
    %%Insert grid interface L-R
    [polDL, polUL] = junction(NL);
    polDL = sparse(polDL);
    polUL = sparse(polUL);
    
    [polLR,polRL] = Interpolation_4(ND+1);
    polRL = sparse(polRL);
    polDL = polRL*polDL;
    polUL = polRL*polUL;
    
    polLD = HIyL*polDL'/HID;
    polLU = HIyL*polUL'/HIU;

    tau_j = -1.2*(bL(xmid)+max([bD(xmid) bU(xmid)]))/(4*alph*min([hL hD hU]));
    beta_j = 0.5;
    gamma_j = -0.5;
    
    interLL =         + kron(tau_j  *HIxL      *(eNxL*eNxL')     ,IyL);
    interLL = interLL + kron(beta_j *HIxL*BSxL'*(eNxL*eNxL')     ,IyL);
    interLL = interLL + kron(gamma_j*HIxL      *(eNxL*eNxL')*BSxL,IyL);
    
    interLD =           kron(tau_j  *HIxL      *(eNxL*-e0D')     ,polLD);
    interLD = interLD + kron(beta_j *HIxL*BSxL'*(eNxL*-e0D')     ,polLD);
    interLD = interLD + kron(gamma_j*HIxL      *(eNxL* e0D')*BSxD,polLD);
    
    interLU =           kron(tau_j  *HIxL      *(eNxL*-e0U')     ,polLU);
    interLU = interLU + kron(beta_j *HIxL*BSxL'*(eNxL*-e0U')     ,polLU);
    interLU = interLU + kron(gamma_j*HIxL      *(eNxL* e0U')*BSxU,polLU);
    
    interDL =           kron(tau_j  *HID      *(-e0D*eNxL')     ,polDL);
    interDL = interDL + kron(beta_j *HID*BSxD'*(-e0D*eNxL')     ,polDL);
    interDL = interDL + kron(gamma_j*HID      *( e0D*eNxL')*BSxL,polDL);
    
    interUL =           kron(tau_j  *HIU      *(-e0U*eNxL')     ,polUL);
    interUL = interUL + kron(beta_j *HIU*BSxU'*(-e0U*eNxL')     ,polUL);
    interUL = interUL + kron(gamma_j*HIU      *( e0U*eNxL')*BSxL,polUL);
    
    %Note that there are two interDD's and interUU's now
    interDD =           kron(tau_j  *HID      *(-e0D*-e0D')     ,ID);
    interDD = interDD + kron(beta_j *HID*BSxD'*(-e0D*-e0D')     ,ID);
    interDD = interDD + kron(gamma_j*HID      *( e0D* e0D')*BSxD,ID);

    interUU =           kron(tau_j  *HIU      *(-e0U*-e0U')     ,IU);
    interUU = interUU + kron(beta_j *HIU*BSxU'*(-e0U*-e0U')     ,IU);
    interUU = interUU + kron(gamma_j*HIU      *( e0U* e0U')*BSxU,IU);
    
    bigD = bigD + [interLL interLD interLU; ...
                   interDL interDD  big0DU; ...
                   interUL  big0UD interUU];

    if eigTest
        val = (eig(full(bigD)));
        plot(real(val),imag(val),'*');
        return;
    end
    
    if stepType==0
        bigbig0 = sparse(bigbigN,bigbigN);
        bigIL = kron(IxL,IyL);
        bigID = kron(ID,ID);
        bigIU = kron(IU,IU);
        bigbigI = [bigIL big0LR; big0RL [bigID big0DU; big0UD bigIU]];
        bigD = [bigbig0 bigbigI; bigD bigbig0];
        Nl = sparse(bigbigN,1);
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
        [v,mov,movTArr] = primStep(v,dt,M,prim,t,mov,movDt,bigbigN);
    end
    if stepType==1
        [v,mov,movTArr] = bisStep(v,v_prev,dt,M,bis,t,mov,movDt,bigbigN);
    end

    %%%%%%% Plotting
    if L2Test
        movL2 = zeros(1,movN);
        for ii = 1:movN
            L2normL = L2(mov(        1 :bigNL ,ii),f(xL,yL,movTArr(ii)),hL);
            L2normD = L2(mov((bigNL+1):(bigNL+bigND),ii),f(xD,yD,movTArr(ii)),hD);
            L2normU = L2(mov((bigNL+bigND+1):bigbigN,ii),f(xU,yU,movTArr(ii)),hU);
            movL2(ii) = sqrt(L2normL^2+L2normD^2+L2normU^2);
        end
        plot(linspace(0,tEnd,movN),movL2);
    end
    
    if movTime && not(L2Test)
        if errTest
            for ii = 1:movN
                mov(1:bigNL,ii) = mov(1:bigNL,ii) ...
                    - f(xL,yL,movTArr(ii));
                mov((bigNL+1):(bigNL+bigND),ii) = mov((bigNL+1):(bigNL+bigND),ii) ...
                    - f(xD,yD,movTArr(ii));
                mov((bigNL+bigND+1):bigbigN,ii) = mov((bigNL+bigND+1):bigbigN,ii) ...
                    - f(xU,yU,movTArr(ii));
            end
        end
        
        movMax = max(max(mov));
        movMin = min(min(mov));
        for ii = 1:movN
            pause(movTime/movN);
            frameL = reshape(mov(       1 :bigNL  ,ii),[2*NL+1 NL+1]);
            frameD = reshape(mov((bigNL+1):(bigNL+bigND),ii),[ND+1 ND+1]);
            frameU = reshape(mov((bigNL+bigND+1):bigbigN,ii),[NU+1 NU+1]);
            surf(xL,yL,frameL);
            hold on;
            surf(xD,yD,frameD);
            surf(xU,yU,frameU);
            hold off;
            axis([xmin xmax ymin ymax movMin movMax]);
            caxis([movMin movMax]);
        end
    end
    
    L2normL = L2(v(        1 :bigNL ),f(xL,yL,tEnd),hL);
    L2normD = L2(v((bigNL+1):(bigNL+bigND)),f(xD,yD,tEnd),hD);
    L2normU = L2(v((bigNL+bigND+1):bigbigN),f(xU,yU,tEnd),hU);

    L2norm = sqrt(L2normL^2+L2normD^2+L2normU^2);
end