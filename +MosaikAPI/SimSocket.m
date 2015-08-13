classdef SimSocket < handle
    %SIMSOCKET TCP socket client for MOSAIK
    %   Provides the basic TCP socket comunication for MOSAIK
    
    properties
        server
        port
        delegate
    end
    
    properties (Access=private)
        socket
        last_id = 0
    end
    
    %% Constructor and Destructor
    methods
        
        function this = SimSocket(server,port,varargin)
            %this = SimSocket(callback,server,port)
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
            addOptional(p,'delegate',[],@(x)isa(x,'ieeh_mosiak_api_matlab.SimSocketDelegate'));
            parse(p,server,port,varargin{:});
            
            this.server = p.Results.server;
            this.port = p.Results.port;
            this.delegate = p.Results.delegate;
            
        end
        
        function delete(this)
            this.delegate = [];
        end
        
    end
    
    %% Private Methods
    methods (Access=private)
        
        function main_loop(this)
            this.socket = tcpclient(this.server,this.port);
            
            while ~strcmp(response,'stop') 
                try
                    % Wait for bytes
                    while ~this.socket.BytesAvailable
                        pause(0.001);
                    end
                    
                    % Read and deserialize the request
                    request = read(this.socket);
                    [~,id,content] = this.deserialize(request);
                    
                    % Forward the request to the Delegate
                    response = content;
                    %response = this.delegate.simSocketReceivedRequest(content);
                    
                    % Serialize and write the response
                    response = this.serialize(response,1,id);
                    write(this.socket,response);
                    
                catch exception
                    this.socket = [];
                    rethrow(exception)
                end
            end
            disp('Terminating Simulator.');
            this.delete;
        end
        
        function message = serialize(~,content,type,varargin)
            % if no id is given it is set automaticaly
            if nargin < 4
                varargin{1}=next_request_id(this);
            end
            
            message{3}=content;
            message{1}=type;
            message{2}=varargin{1};
            
            message = uint8(savejson('',message,'ParseLogical',1,'Compact',1));
            message(2:end+1) = message;
            message(1) = numel(savejson('',message,'ParseLogical',1,'Compact',1));
            message(end+1) = 10;
        end
        
        function [type,id,content] = deserialize(this,message)
            
            message = loadjson(char(message));
            
            type = message{1};
            id = message{2};
            content = message{3};
            
            this.last_id = id;
            
        end
        
        function value = next_request_id(this)
            this.last_id = this.last_id+1;
            value = this.last_id;
        end
        
        
    end
    
    %% Public Methods
    methods
        
        function start(this)
            %assert(~isempty(this.delegate),'You need to specify a delegate before starting the socket');
            this.main_loop();
        end
        
        
        function response = send_request(this,content)
            % Serialize and write the request
            request = this.serialize(content,0);
            write(this.socket,request);
            
            % waiting for response
            while ~this.socket.BytesAvailable
                pause(0.001);
            end
            
            % read the deserialze the response
            response = read(this.socket);
            [~,~,content] = this.deserialize(this,response);
            response = content;
            
        end
        
    end
    
    
    
    
    
    
    
end

