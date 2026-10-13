%% Descobre o waypoint mais proximo da posição atual do robo

function bestPoint = GetClosestWaypoint(robotPos, waypoints)
    % robotPos: [x, y] ou [x, y, theta]
    % waypoints: matriz 4x2 [x, y] com os pontos N, S, E, O
    
    % O (:) garante que fica vetor coluna, o (') transpoe para linha
    robotPos = robotPos(:)'; 
    robotPos = robotPos(1:2); % Fica apenas com X e Y, ignora o Theta se existir

    % Calcula distância a todos os 4 pontos de uma vez
    dists = vecnorm(waypoints - robotPos, 2, 2);
    
    % Encontra o índice da distância mínima
    [~, idx] = min(dists);
    
    % Devolve o ponto vencedor
    bestPoint = waypoints(idx, :);
end