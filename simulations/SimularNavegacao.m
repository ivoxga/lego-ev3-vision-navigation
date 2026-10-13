%% Função para simular as trafetorias da base inicial até às outras 4 bases

function SimularNavegacao(freeZoneMap, waypointsBases, robotCentroid)
    H = size(freeZoneMap, 1); % Obtém a altura da imagem (ex: 1080 pixeis)

    % ----- 1. Configuração do Mapa e Planeador (PRM)
    % Inverter o mapa: 1=Ocupado (Paredes), 0=Livre (Chão)
    navMap = binaryOccupancyMap(~freeZoneMap); 

    % Criar o Probabilistic RoadMap
    prm = mobileRobotPRM(navMap);
    prm.NumNodes = 300;           % Nº de pontos aleatórios
    prm.ConnectionDistance = 150; % Distância máx de ligação

    % ----- 2. Visualização Inicial
    figure('Name', 'Simulação DriveToPoint', 'NumberTitle', 'off');
    imshow(freeZoneMap);
    %show(navMap); 
    axis off;
    hold on;
    title('Trajetórias: Start -> Bases');
    
    colors = {'r', 'y', 'g', 'm'}; % Vermelho, Amarelo, Verde, Roxo
    
    % Posição Inicial [x, y, theta]
    startPose = [robotCentroid(1); robotCentroid(2); 0]; 
    
    % ----- 3. Ciclo das 4 Bases
    for i = 1:4
        % Em vez de fixar waypointsBases{i}(1,:), usamos a função:
        % currentPose(1:2) é a posição X,Y atual do robô
        goalPoint = GetClosestWaypoint(startPose(1:2), waypointsBases{i});
        
        % Desenha o alvo escolhido para confirmação visual
        plot(goalPoint(1), goalPoint(2), 'r.', 'MarkerSize', 15);

        % --- A. PLANEAR (FindPath com Conversão de Coordenadas) ---
        % O 'findpath' precisa de coordenadas Cartesianas (Y sobe)
        % Convertemos: Y_map = Altura - Y_img
        startNodeMap = [startPose(1), H - startPose(2)];
        goalNodeMap  = [goalPoint(1), H - goalPoint(2)];

        % --- A. PLANEAR (FindPath) ---
        pathMap = findpath(prm, startNodeMap, goalNodeMap);

        % Converter o caminho de volta para coordenadas de Imagem para desenhar
        pathImg = pathMap;
        pathImg(:, 2) = H - pathMap(:, 2); % Des-inverter o Y
        
        % Desenha rota ideal (tracejado)
        plot(pathImg(:,1), pathImg(:,2), '--', 'Color', colors{i}, 'LineWidth', 1);
        
        % --- B. EXECUTAR (Controlador) ---
        currentPose = startPose; % Reset ao início (requisito teu)
        fullTrajectory = [];     % Para guardar o rasto
        
        % Seguir cada segmento do caminho planeado
        for j = 2:size(pathImg, 1)
            target = pathImg(j, :);
            
            % Chama a função de controlo para ir até ao próximo nó
            [segmentPose, ~] = driveToPoint(currentPose, target);
            
            % Guarda e Atualiza
            fullTrajectory = [fullTrajectory, segmentPose];
            currentPose = segmentPose(:, end); 
        end
        
        % Desenha o movimento "real" (linha grossa)
        plot(fullTrajectory(1,:), fullTrajectory(2,:), '-', 'Color', colors{i}, 'LineWidth', 2);
        
        % Marca o robot no destino
        plot(currentPose(1), currentPose(2), 'bo', 'MarkerSize', 6, 'LineWidth', 2);
        drawnow; % Força atualização do gráfico
    end
    hold off;
end