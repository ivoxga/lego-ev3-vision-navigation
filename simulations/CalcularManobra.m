%% Determina o proximo waypoint para contornar a base

function [pontoDestino, idxDestino] = CalcularManobra(idxChegada, sinal, waypointsBase)
    % idxChegada: 1=Norte, 2=Sul, 3=Oeste, 4=Este
    % sinal: 'ESQUERDA', 'DIREITA' (ou 'FRENTE'/'STOP' futuramente)
    % waypointsBase: A matriz 4x2 com as coordenadas desta base
    
    idxDestino = idxChegada; % Por defeito, fica onde está
    
    switch idxChegada
        case 1 % Cheguei pelo NORTE (Estou a olhar para baixo)
            if strcmp(sinal, 'ESQUERDA'), idxDestino = 4; end % Minha Esq é Este
            if strcmp(sinal, 'DIREITA'),  idxDestino = 3; end % Minha Dir é Oeste
            
        case 2 % Cheguei pelo SUL (Estou a olhar para cima)
            if strcmp(sinal, 'ESQUERDA'), idxDestino = 3; end % Minha Esq é Oeste
            if strcmp(sinal, 'DIREITA'),  idxDestino = 4; end 
            
        case 3 % Cheguei pelo OESTE (Estou a olhar para a direita)
            if strcmp(sinal, 'ESQUERDA'), idxDestino = 1; end % Minha Esq é Norte
            if strcmp(sinal, 'DIREITA'),  idxDestino = 2; end 
            
        case 4 % Cheguei pelo ESTE (Estou a olhar para a esquerda)
            if strcmp(sinal, 'ESQUERDA'), idxDestino = 2; end % Minha Esq é Sul
            if strcmp(sinal, 'DIREITA'),  idxDestino = 1; end 
    end
    
    % Devolve as coordenadas do ponto para onde ele tem de ir
    pontoDestino = waypointsBase(idxDestino, :);
end