classdef Simulator < MosaikAPI.SimSocketDelegate
    % SIMULATOR   Simulator superclass.
    %   Provides socket communication methods and abstract methods the simulator needs to implement.

    properties (Constant)

        api_version = 2    % API version

    end
    
    properties

        socket             % Associated socket client
        mosaik             % Assiciated mosaik proxy
        sid = 'Matlab'     % Simulator ID
        shutdown = false   % Instance shutdown toggle

    end
    
    
    methods
        
        function this = Simulator(server,varargin)
            % Constructor of the class Simulator
            %
            % Parameter:
            %  - server: Server IP and port as char, format: 'IP:port'
            %  - varargin: Optional parameter value list
            %              debug: false (default)|true - Create the simulator in
            %              debug mode where no socket server is started.
            %              message:output: false (default)|true - Shows socket
            %              communication messages. 
            %
            % Return:
            %  - this: Simulator Object
            
            p = inputParser;
            addRequired(p,'server',@ischar);
            addOptional(p,'debug',false,@islogical);
            parse(p,server,varargin{:});
            
            server = p.Results.server;
            
            % Gets server from mosaik and start tcpclient at given host and port.
            assert(~isempty(strfind(server,':')), 'Wrong server configuration. Check server configuration.')
            [ip,port] = parse_address(this,server);

            this.mosaik = MosaikAPI.MosaikProxy(this);
            
            if ~p.Results.debug
                % Creates socket
                this.socket = MosaikAPI.SimSocket(ip,port,this);
                % Starts the socket client and waiting for messages
                this.socket.start();
                % Delete the Socket
                this.socket = [];
                % Call the finalize methode()
                this.finalize();
                % Close Matlab with timer
                if this.shutdown
                    t = timer();
                    t.StartDelay = 1;
                    t.TimerFcn = @(myTimerObj, thisEvent)exit;
                    start(t);
                end
            end
            
        end        
        
        function value = meta(this)
            % Creates meta struct with empty models struct and extra methods cell.
            %
            % Parameter:
            %  - none
            %
            % Return:
            %  - value: Struct object containing meta information.

            value.api_version = this.api_version;
            value.extra_methods = {};
            value.models = struct;

        end
        
        function response = simSocketReceivedRequest(this,request)
            % Parses request and calls simulator function.

            func = request{1};
            func = str2func(func);
            args = request{2};
            kwargs = request{3};
            if ~isa(args,'cell')
                args = {args};
            end
            if numel(request) > 3
                warning('Request has more than 3 arguments, these will be ignored')
            end
            if ~isempty(kwargs)
                kwargs = [fieldnames(kwargs)';struct2cell(kwargs)'];
            else
                kwargs = {};
            end

            % Calls simulator function with parsed arguments
            response = func(this,args{:},kwargs{:});

        end
        
        function stop = stop(this, ~, ~)
            % Closes socket and returns 'stop'.

            this.socket.stop();
            stop = ('stop');

        end
        
        function meta = init(this, sid, varargin)
            % Sets simulator ID, verifies input arguments. Returns meta struct.

            this.sid = sid;
            
            p = inputParser;
            p.KeepUnmatched = true;
            parse(p,varargin{:})
            
            % TODO step_size must be defined
            if ~isempty(p.Unmatched)
                prop = fieldnames(p.Unmatched);
                for i=1:numel(prop)
                    this.(prop{i}) = p.Unmatched.(prop{i});
                end
            end
            
            meta = this.meta();
            
        end
        
        function finalize(this)
            % Does nothing by default. Can be overridden.

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
    
    methods (Abstract)

        % Abstract model creation method.
        entity_list = create(this,num,model,varargin);

        % Abstract simulator step method.    
        time_next_step = step(this,time,varargin);
        
        % Abstract data return method.    
        data = get_data(this,outputs);        

    end
    
    methods (Static)
        
        function value = concentrateInputs(inputs)
            % Sums up all inputs for each model.
            
            % BUG: does not properly read structs sometimes
            % Workaround
            inputs = loadjson(savejson('',inputs));
            value = structfun(@(x) structfun(@(y) sum(cell2mat(struct2cell(y))),x,'UniformOutput',false), ...
                inputs,'UniformOutput',false);
            
        end

        function names = properFieldnames(this,struct)
            % Removes hard encoding from struct fieldnames.

            names = fieldnames(struct);
            names = cellfun(@(x) strrep(x, '_0x2E_','.'),names,'UniformOutput',false);
            names = cellfun(@(x) strrep(x, '_0x2D_','-'),names,'UniformOutput',false);

        end

    end

end
