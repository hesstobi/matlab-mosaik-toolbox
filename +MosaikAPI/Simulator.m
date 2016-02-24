classdef Simulator < MosaikAPI.SimSocketDelegate
    % SIMULATOR   Simulator superclass.
    %   Provides socket communication methods and abstract methods the simulator needs to implement.

    properties (Constant)

        api_version = '2.1'    % API version

    end
    
    properties

        socket				% Associated socket client
        mosaik				% Assiciated mosaik proxy
        sid = 'Matlab'		% Simulator ID
        verbose				% Verbose mode

    end
    
    
    methods
        
        function this = Simulator(server,varargin)
            % Constructor of the class Simulator.
            %
            % Parameter:
            %  - server: String argument; server ip and port; format: 'ip:port'.
            %  - varargin: Optional arguments.
            %              debug: false (default)|true - Create the simulator in
            %              debug mode where no socket server is started.
            %              verbose: false (default)|true - Shows socket
            %              communication messages. 
            %
            % Return:
            %  - this: Simulator object.
            
            p = inputParser;
            addRequired(p,'server',@ischar);
            addOptional(p,'debug',false,@islogical);
            addOptional(p,'verbose',false,@islogical);
            parse(p,server,varargin{:});
            
            server = p.Results.server;

            this.verbose = p.Results.verbose;

            % Gets server from mosaik and start tcpclient at given host and port.
            assert(~isempty(strfind(server,':')), 'Wrong server configuration. Check server configuration.')
            [ip,port] = this.parseAddress(server);

            this.mosaik = MosaikAPI.MosaikProxy(this);
            
            if ~p.Results.debug
                % Creates socket
                this.socket = MosaikAPI.SimSocket(ip,port,this.verbose,this);
                % Starts the socket client and waiting for messages
                this.socket.start();
                % Delete the Socket
                this.socket = [];
                % Call the finalize methode()
                this.finalize();
                % Close Matlab with timer
                if ~this.verbose
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
            %  - value: Struct object; meta information.

            value.api_version = this.api_version;
            value.extra_methods = {};
            value.models = struct;

        end
        
        function response = simSocketReceivedRequest(this,request)
            % Parses request and calls simulator function.
            %
            % Parameter:
            %  - request: String argument; request message.
            %
            % Return:
            %  - response: Cell object; simulator functions response.

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
        
        function stop = stop(this, varargin)
            % Closes socket and returns 'stop'.
            %
            % Parameter:
            %  - varargin: Empty arguments.
            %
            % Return:
            %  - none

            this.socket.stop();
            stop = ('stop');

        end
        
        function meta = init(this, sid, varargin)
            % Sets simulator ID, verifies input arguments. Returns meta struct.
            %
            % Parameter:
            %  - sid: String argument; simulator id.
            %  - varargin: Optional arguments; initial parameters.
            %
            % Return:
            %  - this: Struct object; simulators meta information.

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

    end
    
    methods (Abstract)

        % Creates models of specified amount, type and initial parameters.
        %
        % Parameter:
        %  - num: Double argument; amount of model to be created.
        %  - model: String argument; type of models to be created.
        %  - varargin: Optional arguments; model parameters.
        %
        % Return:
        %  - entity_list: Cell object; structs with created model
        %                              information.
        entity_list = create(this,num,model,varargin);

        % Performs simulation step.
        %
        % Parameter:
        %  - time: Double argument; time of this simulation step.
        %  - varargin: Struct argument; input values.
        %              Optional arguments.
        %
        % Return:
        %  - time_next_step: Double object; time of next simulation step.
        time_next_step = step(this,time,varargin);
        
        % Receives data for requested attributes.
        %
        % Parameter:
        %  - outputs: Struct argument; requested eids and its
        %                              attributes.
        % Return:
        %  - data: Struct object; eids and values of requested data.
        data = get_data(this,outputs);        

    end
    
    methods (Static)
        
        function value = concentrateInputs(inputs)
            % Sums up all inputs for each model.
            %
            % Parameter:
            %  - inputs: Struct argument; input values.
            %
            % Return:
            %  - value: Struct object; summed up input values.

            
            % BUG: does not properly read structs sometimes
            % Workaround
            inputs = loadjson(savejson('',inputs));
            value = structfun(@(x) structfun(@(y) sum(cell2mat(struct2cell(y))),x,'UniformOutput',false), ...
                inputs,'UniformOutput',false);
            
        end

        function names = properFieldnames(struct)
            % Removes hard encoding from struct fieldnames.
            %
            % Parameter:
            %  - struct: Struct argument.
            %
            % Return:
            %  - names: Cell object; struct fieldnames.

            names = fieldnames(struct);
            names = cellfun(@(x) strrep(x, '_0x2E_','.'),names,'UniformOutput',false);
            names = cellfun(@(x) strrep(x, '_0x2D_','-'),names,'UniformOutput',false);

        end

        function finalize()
            % Does nothing by default. Can be overridden.
            %
            % Parameter:
            %  - none
            %
            % Return:
            %  - none

        end

        function null = setup_done()
            % Returns empty response.
            %
            % Parameter:
            %  - none
            %
            % Return:
            %  - none

            null = [];

        end

        function [ip, port] = parseAddress(server)
            % Parses address string. Returns ip as string and port as integer.
            %
            % Parameter:
            %  - server: String argument; server ip and port; format: 'ip:port'
            %
            % Return:
            %  - ip: String object; socket ip adress.
            %  - port: Double object; socket port.

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

end
