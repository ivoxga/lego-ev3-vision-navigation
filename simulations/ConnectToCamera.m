%% Função para conectar camera

function ConnectToCamera(ip)
    %ip = 'http://172.20.10.12:8080/video';
    
    video = ipcam(ip,'admin','12345');
    
    while(1)
        v = snapshot(video);
    
        imshow(v,[]);
    end
end