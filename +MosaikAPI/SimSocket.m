classdef SimSocket < handle
    % SIMSOCKET  TCP socket client for MOSAIK.
    %   Provides the basic TCP socket comunication for MOSAIK.
    
    properties
        server
        port
        delegate
        message_output = false
    end
    
    properties (Access=private)
        socket
        last_id = 0
        stopServer = false
    end
    
    %% Constructor and Destructor
    methods
        
        function this = SimSocket(server,port,varargin)
            % this = SimSocket(callback,server,port)
            % Constructor of the class SimSocket
            %
            % Parameter:
            %  - server  : Server IP as char
            %  - port    : Server port as numeric
            %  - delegate: the delegate as SimSocketDelegate (optional)
            %
            % Return:
            %  - this: SimSocket Object
            
            % Validate und parse the input
            p = inputParser;
            addRequired(p,'server',@ischar);
            addRequired(p,'port',@(x)validateattributes(x,{'numeric'},{'scalar','integer','positive'}));
            addOptional(p,'delegate',[],@(x)isa(x,'MosaikAPI.SimSocketDelegate'));
            parse(p,server,port,varargin{:});
            
            this.server = p.Results.server;
            this.port = p.Results.port;
            this.delegate = p.Results.delegate;
            this.socket = tcpclient(this.server,this.port);                     
        end
        
        function delete(this)
            this.delegate = [];
        end
        
    end
    
    %% Private Methods
    methods (Access=private)
        
        function main_loop(this)
                        
            while ~this.stopServer 
                try
                    % Wait for bytes
                    while ~this.socket.BytesAvailable
                        pause(0.001);
                    end
                    
                    % Read and deserialize the request
                    request = read(this.socket);
                    [~,id,content] = this.deserialize(request);

                    % Forward the request to the Delegate
                    %response = content;
                    response = this.delegate.simSocketReceivedRequest(content);
                    
                    % Serialize and write the response
                    response = this.serialize(response,1,id);                    
                    write(this.socket,response);
                    
                catch exception
                    this.socket = [];
                    rethrow(exception)
                end
            end
            %disp('Terminating Socket.');
        end
        
        function message = serialize(this,content,type,varargin)
            % if no id is given it is set automaticaly
            if nargin < 4
                varargin{1}=next_request_id(this);
            end
            
            message{3}=content;
            message{1}=type;
            message{2}=varargin{1};            
            
            message = savejson('',message,'ParseLogical',1,'Compact',1);
            message = strrep(message, sprintf('\t'), '');
            message = strrep(message, sprintf('\n'), '');
            message = strrep(message, ',null', '');
            message = strrep(message, 'null,', '');

            this.outp(message);
            message = [this.make_header(message) uint8(message)];
        end
        
        function [type,id,content] = deserialize(this,message)
            
            this.outp(char(message(5:end)));

            message = loadjson(char(message(5:end)));
            
            if ~iscell(message)
                message = num2cell(message);
            end

            type = message{1};
            id = message{2};
            if ~lt(numel(message),3)
                content = message{3};
            else
                content = struct;
            end

            this.last_id = id;
            
        end

        function header = make_header(~, message)
            sizeMessage = numel(message);
            header = typecast(swapbytes(uint32(sizeMessage)),'uint8');
        end
        
        function value = next_request_id(this)
            this.last_id = this.last_id+1;
            value = this.last_id;
        end
        
        function outp(this,message)

            if this.message_output
                disp(message);
            end
        
    end
    
    %% Public Methods
    methods
        
        function start(this)
            assert(~isempty(this.delegate),'You need to specify a delegate before starting the socket');
            this.main_loop();
        end
        
        
        function stop(this)
            this.stopServer = true;
        end
        
        
        function response = send_request(this,content)
            % Serialize and write the request
            request = this.serialize(content,0);
            write(this.socket,request);
            
            % Wait for response
            while ~this.socket.BytesAvailable
                pause(0.001);
            end
            
            % Read and deserialize the response
            response = read(this.socket);
            [~,~,content] = this.deserialize(response);
            response = content;            
        end        
    end
end

