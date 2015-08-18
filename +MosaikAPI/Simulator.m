classdef Simulator < MosaikAPI.SimSocketDelegate

    properties
        api_version = 2;
        meta = containers.Map();
    end

    methods

        function sim = Simulator(server)
            % this = Simulator(server)
            % Constructor of the class Simulator
            %
            % Parameter:
            %  - server  : Server IP and port as char, format: 'IP:port'
            %
            % Return:
            %  - sim: Simulator Object            

            %Error when server is not a string
            assert(ischar(server), 'Wrong server configuration. Check server configuration.')

            %Get server from mosaik and start tcpclient at given host and port.
            assert(~isempty(strfind(server,':')), 'Wrong server configuration. Check server configuration.')
            [ip,port] = parseAddress(sim,server);

            %Creates socket and starts main loop
            MosaikAPI.SimSocket(ip,port,sim);
        end

    end

    methods
                
        function response = simSocketReceivedRequest(sim,request) 
            %Parses request and calls simulator function.
            func = request{1};
            func = str2func(func);
            response = func(sim,request{2:end});
        end

    end

    methods (Access=private)
        
        function null = setup_done(~)
            %Returns empty response.
            null = [];
        end
        
        function [ip, port] = parseAddress(~, server)
            %Parses address string. Returns ip as string and port as integer.
            server = strsplit(server,':');
            if ~isempty(server(1))
                ip = server{1};
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

    end

    methods %(Access=protected)
    methods
    
        function set_delegator(sim, delegator)
            sim.delegator = delegator;
        end

        function meta = updateMeta(sim, meta)
            meta.('api_version') = sim.api_version;
        end

        function stop = stop(~, ~, ~)
            stop = ('stop');
        end
    end


    %Methods the simulator needs to inherit from.
    methods (Abstract)

        init(sim,args,kwargs);

        create(sim,args,kwargs);
        
        step(sim,args,kwargs);

        get_data(sim,args,kwargs);
        
    end
end
