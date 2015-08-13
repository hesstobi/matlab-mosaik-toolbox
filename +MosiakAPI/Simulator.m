classdef Simulator < handle 
    properties
    api_version = 2;
    meta = containers.Map();
    id;
    end
    methods
        function sim = Simulator(server)

            %Error when server is not a string
            assert(ischar(server), 'Wrong server configuration. Check server configuration.')

            %Get server from mosaik and start tcpclient at given host and port.
            assert(~isempty(strfind(server,':')), 'Wrong server configuration. Check server configuration.')
            [ip, port] = parse_addr(sim, server);

            %Creates socket client.
            sock = tcpclient(char(ip),port);

            %Starts listening to mosaik API-calls.
            try
                listen(sim, sock);
            catch me
                response = strcat('[2, ', num2str(sim.id), ', ', me.getReport, ']');
                header = make_header(sim, response);
                write(sock, uint8(sprintf(strcat(header, response))));
                %disp(me.getReport);
            end

        end
    end

    methods  (Access = private)
        
        function listen(sim,sock)

            %Waits for API-calls.
            while eq(sock.BytesAvailable,0)
            end

            %If there is a message sent via socket, it calls the simulator.
            run(sim,sock);

        end

        function run(sim,sock)
            %Reads API call. Splits call in request size and request. 
            request = read(sock);
            disp(request);
            size = request(4);
            request = request(5:end);

            %Checks if API call has the correct size.
            if ~eq(numel(request), size)
                request = char(request);
                in = regexp(request, ',');
                sim.id = request(in(1)+1:in(2)-1);
                error('Did not read correct API-call.');
            end

            %Converts request to string.
            request = char(request);

            %Parses request.
            request = loadjson(request);

            %Calls request function. Returns response.
            response = exec(sim, request);
            
            %If response is not 'stop', parses correct response string and sends it via socket.
            if ~strcmp(response,'stop')
                if ~isnumeric(response)
                    response = strrep(response, sprintf('\t'), '');
                    response = strrep(response, sprintf('\n'), '');
                    response = strrep(response, ',null', '');
                    response = strcat('[1, ', num2str(sim.id), ', ', response, ']');
                else
                    response = strcat('[1, ', num2str(sim.id), ', ', num2str(response), ']');
                end
                response = strrep(response, sprintf(' '), '');

                %Creates header containing response size.
                header = make_header(sim, response);

                write(sock, uint8(sprintf(strcat(header, response))));
            end

            %If response is stop, closes simulator instance, if not, continues to listen to API calls.
            if strcmp(response, 'stop')                
                disp('Terminating simulator.')
            else
                listen(sim,sock)
            end

        end

        
        function response = simSocketReceivedRequest(sim,~,request) 
            %Parses request and calls simulator function.
            func = request{1};
            func = str2func(func);
            response = func(sim, request{2:end});
        end

        %Returns empty response.
        function null = setup_done(~)
            null = [];
        end

        %Parses address string. Returns ip as string and port as integer.
        function [ip, port] = parse_addr(~, server)
            server = strsplit(server,':');
            if ~isempty(server(1))
                ip = server(1);
            else
                error('No server IP entered. Check server configuration.')
            end
            if ~isempty(server(2))
                port = server(2);
                port = str2double(port{:});
                assert(isnumeric(port), 'Wrong server port. Check server configuration.')
            else
                error('No server port entered. Check server configuration.')
            end
        end

        function header = make_header(~, response)
            size = numel(uint8(response));
            size = dec2hex(size);
            header = '\x00\x00\x00\x00';
            for i = 1:numel(size)
                j = i-1;
                if eq(i, 3) || eq(i, 4) || eq(i, 7) || eq(i, 8) || eq(i, 11) || eq(i, 12) || eq(i, 15) || eq(i, 16)
                    j = j + 2;
                end
                header(16-j)= size(numel(size)+1-i);              
            end
        end
    end

    %Methods the simulator needs to inherit from.
    methods (Access = protected)
        function meta = init(sim, meta)
            meta.('api_version') = sim.api_version;
        end

        function stop = stop(~, ~, ~)
            stop = ('stop');
        end

        function create(sim, ~, ~, ~)
        end
        
        function step(sim, ~, ~)
        end

        function get_data(sim, ~)
        end
        
    end
end
