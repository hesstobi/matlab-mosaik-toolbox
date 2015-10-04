classdef Simulator < handle & MosaikAPI.SimSocketDelegate
    
    properties (Constant)
        api_version = 2
    end
    
    properties (Access=private)
        socket;
    end
    
    properties
        sid = 'Matlab'
    end
    
    
    methods
        
        function this = Simulator(server,varargin)
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
            %  - this: Simulator Object
            
            p = inputParser;
            addRequired(p,'server',@ischar);
            addOptional(p,'debug',false,@islogical);
            parse(p,server,varargin{:});
            
            server = p.Results.server;
            
            %Get server from mosaik and start tcpclient at given host and port.
            assert(~isempty(strfind(server,':')), 'Wrong server configuration. Check server configuration.')
            [ip,port] = parse_address(this,server);
            
            if ~p.Results.debug
                %Creates socket
                this.socket = MosaikAPI.SimSocket(ip,port,this);
                %Starts the socket client and waiting for messages
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
            % Creates meta struct with empty mpdels struct and extra methods cell
            value.api_version = this.api_version;
            value.extra_methods = {};
            value.models = struct;
        end
        
    end
    
    
    
    methods
        
        function response = simSocketReceivedRequest(this,request)
            %Parses request and calls simulator function.
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
            this.socket.stop();
            stop = ('stop');
        end
        
        function progress = get_progress(this)
            content{1} = 'get_progress';
            content{2} = {{}};
            content{3} = struct;
            progress = this.socket.send_request(content);
        end
        
    end
    
    
    
    
    
    %% Mosaik API
    
    methods
        function meta = init(this, sid, varargin)
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
            
            meta = this.meta;
        end
        
        function finalize(this)
            % Do nothing by default
        end
        
        function related_entities = as_get_related_entities(this, varargin)        
            content{1} = 'get_related_entities';        
            if gt(nargin,1)
                if ischar(varargin{1})
                    varargin =  [this.sid cellstr(varargin{1})];
                end
                varargin{end+1} = {[]};
            else
                varargin{end+1} = {{}};
            end
            content{2} = varargin;
            content{3} = struct;
            related_entities = this.socket.send_request(content);
        end
        
        function data = as_get_data(sim, varargin)
            content{1} = 'get_data';
            if iscell(varargin{1})
                varargin =  varargin{1};
            else
                varargin{end+1} = {[]};
            end
            content{2} = varargin;
            content{3} = struct;
            data = sim.socket.send_request(content);
        end
        
        function as_set_data(sim, varargin)
            content{1} = 'set_data';
            if iscell(varargin{1})
                varargin =  varargin{1};
            else
                varargin{end+1} = {[]};
            end
            content{2} = varargin;
            content{3} = struct;
            sim.socket.send_request(content);
        end
        
    end
    
    
    methods (Abstract)
        create(this,num,model,varargin)
        step(this,time,varargin);
        get_data(this, outputs);
    end
    
    
    %% Utilities
    
    methods (Static)
        
        function value = concentrateInputs(inputs)
            
            value = structfun(@(x) structfun(@(y) sum(cell2mat(struct2cell(y))),x,'UniformOutput',false), ...
                inputs,'UniformOutput',false);
            % TODO does not work when src_ids given in inputs
            
        end
        
        
    end
end
