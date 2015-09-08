classdef Simulator < handle & MosaikAPI.SimSocketDelegate

    properties (Constant)
        api_version = 2
    end
       
    properties (Access=private)
        socket;
    end

    methods

        function sim = Simulator(server,varargin)
            % this = Simulator(server)
            % Constructor of the class Simulator
            %
            % Parameter:
            %  - server  : Server IP and port as char, format: 'IP:port'
            %  - varargin: Optional Parameter Value List
            %              debug: false|true - Create the Simulator in
            %              debug Mode where no Socket Server is started.
            %
            % Return:
            %  - sim: Simulator Object
            
            p = inputParser;
            addRequired(p,'server',@ischar);
            addOptional(p,'debug',false,@islogical);
            parse(p,server,varargin{:});
            
            server = p.Results.server;

            %Get server from mosaik and start tcpclient at given host and port.
            assert(~isempty(strfind(server,':')), 'Wrong server configuration. Check server configuration.')
            [ip,port] = parse_address(sim,server);

            %Creates socket
            sim.socket = MosaikAPI.SimSocket(ip,port,sim);
            
            
            if ~p.Results.debug
                %Starts the socket client and waiting for messages
                sim.socket.start();
                % Delete the Socket
                sim.socket = [];
                % Close Matlab
                pause(10);
                exit;
            end
           
        end
        
        
        function value = meta(this)
           value.api_version = this.api_version;
           value.extra_methods = {};
           value.models = struct; 
        end

    end

    methods
                
        function response = delegate(sim,request) 
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
        
        function [ip, port] = parse_address(~, server)
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

    methods
    
        function meta = update_meta(sim, meta)
            meta.('api_version') = sim.api_version;
        end

        function stop = stop(~, ~, ~)
            stop = ('stop');
        end

        function progress = get_progress(sim)
            content{1} = 'get_progress';
            content{2} = [];
            content{3} = {};
            progress = sim.socket.send_request(content);
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
