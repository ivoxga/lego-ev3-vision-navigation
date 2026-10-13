%% Função que processa a imagem RGB da arena

function [freeZoneMap, waypointsBases, robotCentroid] = ProcessedMap(map) 
    
    % --- 1. Processamento Inicial ---
    originalImage = imread(map);
    hsvImage = rgb2hsv(originalImage);
    H = hsvImage(:,:,1); 
    S = hsvImage(:,:,2); 
    V = histeq(hsvImage(:,:,3));

    % --- 2. Mascara da Arena (Preto/Branco) ---
    blackMask = (V < 0.15);
    blackMaskCleaned = bwareaopen(blackMask, 200);
    blackMaskFilled = imfill(imclose(blackMaskCleaned, strel('disk',8)), "holes");
    
    % Identificar a borda da arena
    labeledBlackObjs = bwlabel(blackMaskFilled);                              
    blackProps = regionprops(labeledBlackObjs,'Area');
    [~, biggestBlackIdx] = max([blackProps.Area]);       
    delimitationMask = (labeledBlackObjs == biggestBlackIdx);
    
    % Chão da Arena (Branco)
    WhiteMask = (S <= 0.2 & V >= 0.5) & delimitationMask;
    WhiteMaskFilled = imfill(imclose(bwareaopen(WhiteMask,200), strel('disk',15)), "holes");
    
    % Filtrar maior objeto branco (o chão jogável)
    labeledWhiteObjs = bwlabel(WhiteMaskFilled);                              
    whiteProps = regionprops(labeledWhiteObjs,'Area');
    [~, biggestWhiteIdx] = max([whiteProps.Area]);          
    boardMask = (labeledWhiteObjs == biggestWhiteIdx);

    % --- 3. Deteção do Robô ---
    blackMaskRobot = (V < 0.15) & boardMask; % Procura preto DENTRO do tabuleiro
    blackMaskRobot = imclose(blackMaskRobot, strel('disk',8));
    blackMaskFilledRobot = bwareaopen(imfill(blackMaskRobot,"holes"), 200);
    
    % Obter silhueta e centro do robô
    robotProps = regionprops(blackMaskFilledRobot, 'Centroid');
    if ~isempty(robotProps)
        robotCentroid = robotProps(1).Centroid;
    else
        robotCentroid = [0,0]; % Fallback
    end
    
    % --- 4. Calibração das Bases (Cores) ---    
    % CORREÇÃO: Parênteses adicionados no Vermelho para isolar o H
    colorMask{1} = ((H > 0.90 | H < 0.07) & S > 0.6 & V < 0.60) & boardMask;    % Vermelho
    colorMask{2} = (H > 0.10 & H < 0.20 & S > 0.40 & V > 0.40) & boardMask;     % Amarelo
    colorMask{3} = (H > 0.25 & H < 0.45 & S > 0.30 & V > 0.20) & boardMask;     % Verde
    colorMask{4} = (H > 0.65 & H < 0.92 & S > 0.20 & V > 0.20) & boardMask;     % Roxo

    dilatedBaseMasks = false(size(H));
    processedBases = cell(1, 4);
    
    for i = 1:4
        processedBases{i} = bwareaopen(colorMask{i}, 500); % Limpeza de ruido
        dilatedBaseMasks = dilatedBaseMasks | processedBases{i};
    end
    
    % --- 5. Zonas de Segurança (Inflação) ---
    robotInflatedBases = cell(1, 4);
    allInflatedBases = false(size(H));
    
    for i = 1:4
        % DICA: Use 'disk' em vez de 'rectangle' para navegação mais suave
        robotInflatedBases{i} = imdilate(processedBases{i}, strel('disk', 40)); 
        allInflatedBases = allInflatedBases | robotInflatedBases{i};
    end
    
    % --- 6. Mapa Final (Free Zone) ---
    % Zonas livres = Tabuleiro - (Bases Infladas + Paredes) + Onde o Robô está agora
    freeZoneMap = (boardMask & ~allInflatedBases) | blackMaskFilledRobot;

    % --- 7. VISUALIZAÇÃO FINAL (Corrigida) ---
    figure('Name', 'Debug: Mapa e Bases Retangulares', 'NumberTitle', 'off');
    imshow(freeZoneMap);
    title('Mapa Binário: Bases (Sólido) vs Zona Segurança (Tracejado)');
    hold on;
    
    % Plot Robô
    if robotCentroid(1) > 0
        plot(robotCentroid(1), robotCentroid(2), 'bo', 'MarkerSize', 10, 'LineWidth', 3);
        text(robotCentroid(1)+20, robotCentroid(2), 'Robô', 'Color', 'cyan');
    end

    % Definição de cores para o plot (ordem: 1-Verm, 2-Amarelo, 3-Verde, 4-Roxo)
    cores = {'r', 'y', 'g', 'm'}; 

    % Inicializar output de waypoints
    waypointsBases = cell(1,4);

    for i = 1:4 
        % 1. Processar a BASE REAL (A folha de papel)
        % Usamos 'processedBases{i}' que é a máscara original sem dilatação
        propsReal = regionprops(processedBases{i}, 'BoundingBox', 'Area', 'Centroid');
        
        if ~isempty(propsReal)
            [~, idxReal] = max([propsReal.Area]);
            baseReal = propsReal(idxReal);
            
            % Desenha o retangulo da BASE REAL (Linha grossa sólida)
            rectangle('Position', baseReal.BoundingBox, 'EdgeColor', cores{i}, 'LineWidth', 3);
            
            % Mete o número no centro da base real
            text(baseReal.Centroid(1), baseReal.Centroid(2), num2str(i), ...
                 'Color', 'white', 'FontSize', 14, 'FontWeight', 'bold');
        end

        % 2. Processar a ZONA DE SEGURANÇA (Onde o robot para)
        % Usamos 'robotInflatedBases{i}' (a versão dilatada)
        propsSafe = regionprops(robotInflatedBases{i}, 'BoundingBox', 'Area');
        
        if ~isempty(propsSafe)
            [~, idxSafe] = max([propsSafe.Area]);
            baseSafe = propsSafe(idxSafe);
            
            % Desenha a zona de segurança (Linha tracejada fina)
            rectangle('Position', baseSafe.BoundingBox, 'EdgeColor', cores{i}, ...
                      'LineWidth', 1, 'LineStyle', '--');
            
            % --- CÁLCULO DOS WAYPOINTS (Nos limites da zona de segurança) ---
            bb = baseSafe.BoundingBox;
            x = bb(1); y = bb(2); w = bb(3); h = bb(4);
            
            % 4 Pontos (Norte, Sul, Oeste, Este)
            ptNorte = [x + w/2,  y];
            ptSul   = [x + w/2,  y + h];
            ptOeste = [x,        y + h/2];
            ptEste  = [x + w,    y + h/2];
            
            wP = [ptNorte; ptSul; ptOeste; ptEste];
            waypointsBases{i} = wP; 
           
            % Desenha os pontinhos brancos onde o robot vai tentar chegar
            plot(wP(:,1), wP(:,2), 'r.', 'MarkerSize', 15); 
        end
    end
    hold off;
end