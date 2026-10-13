%% Simula tragetoria em sequencia 

function SimularSequencia(freeZoneMap, waypointsBases, robotCentroid)
    % sequencia
    sequencia = [1, 2, 3, 4];

    % 1. Configuração (Mapa e PRM)
    H = size(freeZoneMap, 1);
    navMap = binaryOccupancyMap(~freeZoneMap);
    prm = mobileRobotPRM(navMap);
    prm.NumNodes = 400; prm.ConnectionDistance = 200;

    % 2. Visualização
    figure; imshow(freeZoneMap); axis off; hold on;
    
    % 3. Lógica Sequencial
    currentPose = [robotCentroid(1); robotCentroid(2); 0]; 
    
    for i = 1:length(sequencia)
        baseIdx = sequencia(i); % Qual a próxima base da lista?

        % A. Escolher Waypoint (Função externa)
        goalPoint = GetClosestWaypoint(currentPose, waypointsBases{baseIdx});
        plot(goalPoint(1), goalPoint(2), 'rx', 'LineWidth', 2);
        
        % B. Planear (PRM)
        path = findpath(prm, [currentPose(1), H-currentPose(2)], [goalPoint(1), H-goalPoint(2)]);
        if isempty(path), continue; end
        
        % C. Converter caminho para imagem
        pathImg = path; pathImg(:,2) = H - path(:,2);
        plot(pathImg(:,1), pathImg(:,2), 'g');
        
        % D. Executar (Função externa - reutilizável!)
        for k = 2:size(pathImg, 1)
            [pose,~] = driveToPoint(currentPose, pathImg(k,:)); 
            currentPose = pose(:, end); % Atualiza a posição real do robô
        end
        
        % ---------------------------------------------------------
        % FASE 2: LÓGICA DO SINAL E CONTORNO
        % ---------------------------------------------------------
        
        % 1. Descobrir onde chegámos
        dists = vecnorm(waypointsBases{baseIdx} - currentPose(1:2)', 2, 2);
        [~, idxChegada] = min(dists);
        
        % 2. SIMULAÇÃO DO SINAL
        if mod(i, 2) ~= 0, sinal = 'ESQUERDA'; else, sinal = 'DIREITA'; end
        fprintf('Base %d: Cheguei ao Ponto %d. Sinal: %s\n', baseIdx, idxChegada, sinal);
        
        % 3. CALCULAR MANOBRA
        [pontoManobra, idxSaida] = CalcularManobra(idxChegada, sinal, waypointsBases{baseIdx});
        
        % 4. Executar se houver mudança
        if idxSaida ~= idxChegada
            fprintf('  -> A contornar para o Ponto %d...\n', idxSaida);
            
            % CORREÇÃO: Usar o PRM para contornar a esquina sem cortar caminho
            pathManobra = findpath(prm, [currentPose(1), H-currentPose(2)], [pontoManobra(1), H-pontoManobra(2)]);
            
            if ~isempty(pathManobra)
                pathM_Img = pathManobra; pathM_Img(:,2) = H - pathManobra(:,2);
                
                % Executa o caminho da manobra ponto a ponto
                for k = 2:size(pathM_Img, 1)
                    [poseContorno, ~] = driveToPoint(currentPose, pathM_Img(k,:));
                    
                    % Desenha o rasto do movimento ENQUANTO ele acontece
                    plot(poseContorno(1,:), poseContorno(2,:), 'r-', 'LineWidth', 2); 
                    drawnow; % Força o MATLAB a atualizar o gráfico agora
                    
                    currentPose = poseContorno(:, end);
                end
                
                % Desenha o rasto vermelho da manobra
                plot(currentPose(1), currentPose(2), 'rx', 'MarkerSize', 5);
                drawnow;
            end
        end     
    end
    % Marca chegada
    plot(currentPose(1), currentPose(2), 'bo', 'LineWidth', 3);
end