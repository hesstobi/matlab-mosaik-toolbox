classdef Simulator < handle & MosaikAPI.SimSocketDelegate
    % SIMULATOR   Superclass for simulators.
    %   Provides socket communication methods and abstract methods the simulator needs to implement.

    properties (Constant)
        api_version = 2;    % API version
    end
    
    properties
        socket;
        mosaik;
        sid = 'Matlab';     % Simulator ID
    end
    
    
    methods
        
        function this = Simulator(server,varargin)
            % Constructor of the class Simulator.
            %
            % Parameter:
            %  - server: Server IP and port as char, format: 'IP:port'
            %  - varargin: Optional Parameter Value List
            %              debug: false|true - Create the Simulator in
            %              debug Mode where no Socket Server is started.
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
                t = timer();
                t.StartDelay = 1;
                t.TimerFcn = @(myTimerObj, thisEvent)exit;
                start(t);
            end
            
        end        
        
        function value = meta(this)
            % Creates meta struct with empty models struct and extra methods cell.

            value.api_version = this.api_version;
            value.extra_methods = {};
            value.models = struct;
        end
        
    end
    
    
    
    methods
        
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
    
    
    methods (Abstract)
        create(this,num,model,varargin)
        % Creates num amount of model models. Passes varargin as argument.
        step(this,time,varargin);
        % Makes a time wide step. Passes varargin as argument.
        get_data(this,outputs);
        % Returns data for outputs.
    end    
    
    %% Utilities
    
    methods (Static)
        
        function value = concentrateInputs(inputs)
            % Sums up all inputs for each model.
            
            value = structfun(@(x) structfun(@(y) sum(cell2mat(struct2cell(y))),x,'UniformOutput',false), ...
                inputs,'UniformOutput',false);
            % TODO does not work when src_ids given in inputs
            
        end
        
        
    end
end
