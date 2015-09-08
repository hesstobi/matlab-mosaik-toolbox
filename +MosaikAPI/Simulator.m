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
            response = func(sim,args{:},kwargs{:});
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

    %% Mosaik API
    
    methods
        function meta = init(sim, sid, varargin)
            sim.sid = sid;
            
            p = inputParser;
            p.KeepUnmatched = true;
            parse(p,varargin{:})
                       
            if ~isempty(p.Unmatched)
                prop = fieldnames(p.Unmatched);
                for i=1:numel(prop)
                    sim.(prop{i}) = p.Unmatched.(prop{i});
                end
            end
            
            meta = sim.meta;
        end
    end
    
    
    methods (Abstract) 
        create(sim,num,model,varargin)
        step(sim,time,inputs);
        get_data(sim, outputs);
    end
    
    
    %% Utilities
    
    methods (Static)
       
        function value = concentrateInputs(inputs)
            
            value = structfun(@(x) structfun(@(y) sum(cell2mat(struct2cell(y))),x,'UniformOutput',false), ...
                inputs,'UniformOutput',false);
             
        end
         
               
    end
      
end
