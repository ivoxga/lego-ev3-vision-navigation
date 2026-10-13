%% Controlador (Peter Corke / DriveToPoint)
function [poseHistory, v_all] = driveToPoint(startPose, goalPoint)
    % Adiciona a pasta do Peter Corke ao caminho do MATLAB
    addpath('C:\Users\ivox2\Documents\IPCA EEC\3º Ano\1º Semestre\Robótica\MatLab_libraries\functionsRoboticaMovel\PeterCorke');

    % Configuração do Robô
    R = 0.1; L = 0.5;                
    dd = DifferentialDrive(R, L);
    
    % Ganhos e Tempo
    sampleTime = 0.05;      % Passo de tempo (simulação mais rápida)
    Kv = 0.8; 
    Kh = 2.5;     % Ganhos Proporcionais
    
    xactual = startPose(:);
    xg = goalPoint(:);
    
    poseHistory = xactual;
    v_all = [];
    count = 1;
    
    % Loop de Controlo
    while (norm(xg(1:2) - xactual(1:2)) > 5) % Tolerância de 5 pixels
        
        % 1. Calcular Erros
        dist_err = norm(xg(1:2) - xactual(1:2));
        ang_target = atan2(xg(2)-xactual(2), xg(1)-xactual(1));
        ang_err = angdiff(ang_target, xactual(3));
        
        % 2. Lei de Controlo (Proporcional)
        % Se o ângulo for grande (>45º), roda primeiro (Spin Turn)
        if abs(ang_err) > deg2rad(45)
            m_v = 0;
            m_w = Kh * ang_err;
        else
            m_v = Kv * dist_err;
            m_w = Kh * ang_err;
        end
        
        % Saturação (Simular limites reais)
        m_v = min(m_v, 30); % Max velocidade pixeis/s
        
        % 3. Cinemática (Inversa -> Direta)
        [wL, wR] = inverseKinematics(dd, m_v, m_w);
        [v, w] = forwardKinematics(dd, wL, wR);
        
        % 4. Integração (Mover no Mundo)
        velWorld = bodyToWorld([v;0;w], xactual);
        xactual = xactual + velWorld * sampleTime;
        
        % Guardar
        poseHistory(:, count+1) = xactual;
        count = count + 1;
        
        if count > 2000, break; end % Break de segurança
    end
end

%% Função auxiliar
function d = angdiff(th1, th2)
    d = mod((th1 - th2) + pi, 2*pi) - pi;
end