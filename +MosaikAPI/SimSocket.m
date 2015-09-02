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
                     
        end
        
        function delete(this)
            this.delegate = [];
        end
        
    end
    
    %% Private Methods
    methods (Access=private)
        
        function main_loop(this)
            this.socket = tcpclient(this.server,this.port);
            
            content = {'init'};
            while ~strcmp(content{1},'stop') 
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
                    response = this.delegate.delegate(content);
                    
                    % Serialize and write the response
                    response = this.serialize(response,1,id);                    
                    write(this.socket,response);
                    
                catch exception
                    this.socket = [];
                    rethrow(exception)
                end
            end
            disp('Terminating Simulator.');
            %this.delete();
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
            
            header = make_header(this,message);

            message = uint8(sprintf(strcat(header, message)));
        end
        
        function [type,id,content] = deserialize(this,message)
            
            disp(char(message(5:end)));

            message = loadjson(char(message(5:end)));

            type = message{1};
            id = message{2};
            content = message{3};      

            this.last_id = id;
            
        end

        function header = make_header(~, message)
            size = numel(uint8(message));
            size = dec2hex(size);
            header = '\x00\x00\x00\x00';
            for i = 1:numel(size)
                j = i-1;
                if eq(i, 3) || eq(i, 4) || eq(i, 7) || eq(i, 8) || eq(i, 11) || eq(i, 12) || eq(i, 15) || eq(i, 16)
                    j = j + 2;
                end
                header(16-j)= size(numel(size)+1-i);              
            end
            disp(header);
        end
        
        function value = next_request_id(this)
            this.last_id = this.last_id+1;
            value = this.last_id;
        end
        
        
    end
    
    %% Public Methods
    methods
        
        function start(this)
            assert(~isempty(this.delegate),'You need to specify a delegate before starting the socket');
            this.main_loop();
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
            [~,~,content] = this.deserialize(this,response);
            response = content;            
        end        
    end
end

