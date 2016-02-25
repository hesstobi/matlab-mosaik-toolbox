classdef SimSocket < handle
    % SIMSOCKET  TCP socket client for MOSAIK.
    %   Provides the basic TCP socket comunication for MOSAIK.
    
    properties
        
        server					% Server IP
        port					% Server Port
        delegate				% Associated delegate
        verbose 				% Verbose mode
        
    end
    
    properties (Access=private)
        
        socket					% Associated tcpclient
        last_id = 0				% Last socket message id
        stopServer = false		% Server shutdown trigger
        bufferRemainder = []    % Incomplete Request data
        messageCue = {}         % OpenMessageCue
    end
    
    methods
        
        function this = SimSocket(server,port,varargin)
            % Constructor of the class SimSocket.
            %
            % Parameter:
            %  - server: String argument; server ip.
            %  - port: Double argument; server port.
            %  - varargin: Optional arguments;
            %                - verbose: verbose communication output
            %                - delegate: associated delegate instance.
            %
            % Return:
            %  - this: SimSocket object.
            
            % Validate und parse the input
            p = inputParser;
            addRequired(p,'server',@ischar);
            addRequired(p,'port',@(x)validateattributes(x,{'numeric'},{'scalar','integer','positive'}));
            addOptional(p,'verbose',false,@islogical);
            addOptional(p,'delegate',[],@(x)isa(x,'MosaikAPI.SimSocketDelegate'));
            parse(p,server,port,varargin{:});
            
            this.server = p.Results.server;
            this.port = p.Results.port;
            this.verbose = p.Results.verbose;
            this.delegate = p.Results.delegate;
            this.socket = tcpclient(this.server,this.port);
            
        end
        
        function delete(this)
            % Remove associated delegate.
            %
            % Parameter:
            %  - none
            %
            % Return:
            %  - none
            
            this.delegate = [];
            
        end
        
    end
    
    methods (Access=private)
        
        function mainLoop(this)
            % Waits for message, deserializes it, sends request to delegate,
            % receives answer from delegate, serializes it, sends it socket.
            %
            % Parameter:
            %  - none
            %
            % Return:
            %  - none
            
            while ~this.stopServer
                try
                    
                    % Read Messages form the Socket
                    messages = this.readSocket();
                    
                    % Add messages from the and clear the message cue
                    messages = horzcat(this.messageCue,messages);
                    this.messageCue = {};
                    
                    % Response to each message
                    for idx = 1:numel(messages)
                        [~,id,content] = this.deserialize(messages{idx});
                        
                        % Forward the request to the Delegate
                        %response = content;
                        response = this.delegate.simSocketReceivedRequest(content);
                        
                        % Serialize and write the response
                        response = this.serialize(response,1,id);
                        write(this.socket,response);
                        
                    end
                    
                    
                catch exception
                    this.socket = [];
                    rethrow(exception)
                end
            end
            
        end
        
        function messages = readSocket(this)
            % Waits for Messages in the Socket and return these
            % Usaly this should be only one message
            
            % Wait for bytes
            while ~this.socket.BytesAvailable
                pause(0.001);
            end
            
            % Read the socket
            buffer = read(this.socket);
            buffer = [this.bufferRemainder buffer];
            this.bufferRemainder = [];
            
            messages = this.splitRequest(buffer);
        end
        
        
        function messages = splitRequest(this,buffer)
            % Splits the received buffer into the different messages,
            % saves incomplete messages to for next loop
            
            messages = {};
            
            while numel(buffer)>0
                
                try
                    messageLength = sum(uint32(buffer(1:4)).*uint32([4 3 2 1].^8));
                catch ME
                    if strcmp(ME.identifier,'MATLAB:badsubscript')
                        this.bufferRemainder = buffer;
                        break;
                    end
                    rethrow(ME)
                end
                
                try
                    messages{end+1} = buffer(5:messageLength+4);
                catch ME
                    if strcmp(ME.identifier,'MATLAB:badsubscript')
                        this.bufferRemainder = buffer;
                        break;
                    end
                    rethrow(ME)
                end
                
                buffer = buffer(messageLength+5:end);
                
            end
            
        end
        
        
        
        function message = serialize(this,content,type,varargin)
            % Converts response from Matlab data types to JSON.
            %
            % Parameter:
            %  - content: String argument; message content.
            %  - type: Double argument; message type.
            %  - varargin: Double argument; message id.
            %
            % Return:
            %  - message: Bytes object; socket message.
            
            % if no id is given it is set automaticaly
            if nargin < 4
                varargin{1}=nextRequestID(this);
            end
            
            message{3}=content;
            message{1}=type;
            message{2}=varargin{1};
            try
                message = savejson('',message,'ParseLogical',1,'Compact',1);
            catch ME
                if strcmp(ME.identifier,'MATLAB:UndefinedFunction')
                    msg = ['To use this Toolbox you need to have ',...
                        'the JSONlab Tollbox installed. You can download it form ', ...
                        'MatlabCentral: <a href="https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files">JSONlab</a>'];
                    causeException = MException('MOSAIKAPI:SimSocket:dependencies',msg);
                    ME = addCause(ME,causeException);
                end
                rethrow(ME)
            end
            
            if ~isempty(strfind(message,'_0x2D_'))
                if this.verbose
                    disp(message)
                    warning('MOSAIKAPI:SimSocket:jsonwarming','Replace _0x2D_ in message to mosiak')
                end
                message = strrep(message, '_0x2D_','-');
            end
            
            if ~isempty(strfind(message,'_0x2E_'))
                if this.verbose
                    disp(message)
                    warning('MOSAIKAPI:SimSocket:jsonwarming','Replace _0x2E_ in message to mosiak')
                end
                message = strrep(message, '_0x2E_','.');
            end
            
            if ~isempty(strfind(message,sprintf('\t')))
                if this.verbose
                    disp(message)
                    warning('MOSAIKAPI:SimSocket:jsonwarming','Replace \\t in message to mosiak')
                end
                message = strrep(message, sprintf('\t'),'');
            end
            
            if ~isempty(strfind(message,sprintf('\n')))
                if this.verbose
                    disp(message)
                    warning('MOSAIKAPI:SimSocket:jsonwarming','Replace \\n in message to mosiak')
                end
                message = strrep(message, sprintf('\n'),'');
            end
            
            if ~isempty(strfind(message,',null'))
                if this.verbose
                    disp(message)
                    warning('MOSAIKAPI:SimSocket:jsonwarming','Replace ,null in message to mosiak')
                end
                message = strrep(message, ',null','');
            end
            
            if ~isempty(strfind(message,'null,'))
                if this.verbose
                    disp(message)
                    warning('MOSAIKAPI:SimSocket:jsonwarming','Replace null, in message to mosiak')
                end
                message = strrep(message, 'null,','');
            end
            
            if this.verbose
                disp(message);
            end
            
            message = [this.makeHeader(message) uint8(message)];
            
        end
        
        
        function [type,id,content] = deserialize(this,message)
            % Converts request from JSON to Matlab data types.
            %
            % Parameter:
            %  - message: Byte argument; socket message.
            %
            % Return:
            %  - type: Double object; message type;
            %  - id: Double object; message id;
            %  - content: String object; message content.
            
            message = char(message);
            
            
            if ~isempty(strfind(message,',null'))
                if this.verbose
                    disp(message)
                    warning('MOSAIKAPI:SimSocket:jsonwarming','Replace ,null in message from mosiak')
                end
                message = strrep(message, ',null','');
            end
            
            if ~isempty(strfind(message,'null,'))
                if this.verbose
                    disp(message)
                    warning('MOSAIKAPI:SimSocket:jsonwarming','Replace null, in message from mosiak')
                end
                message = strrep(message, 'null,','');
            end
            
            message = strrep(message, 'null','0');
            
            if this.verbose
                disp(message);
            end
            
            try
                message = loadjson(message);
            catch ME
                if strcmp(ME.identifier,'MATLAB:UndefinedFunction')
                    msg = ['To use this Toolbox you need to have ',...
                        'the JSONlab Tollbox installed. You can download it form ', ...
                        'MatlabCentral: <a href="https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files">JSONlab</a>'];
                    causeException = MException('MOSAIKAPI:SimSocket:dependencies',msg);
                    ME = addCause(ME,causeException);
                end
                rethrow(ME)
            end
            
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
            
            if type == 2
                msgID = 'MOSAIKAPI:SimSocket:MosaikError';
                ME = MException(msgID,strrep(content, '\', '\\'));
                throw(ME);
            end
            
            this.last_id = id;
            
        end
        
        function value = nextRequestID(this)
            % Creates next message id.
            
            %
            % Parameter:
            %  - none
            %
            % Return:
            %  - value: Double object; message id.
            
            this.last_id = this.last_id+1;
            value = this.last_id;
            
        end
        
    end
    
    methods
        
        function start(this)
            % Starts main loop.
            %
            % Parameter:
            %  - none
            %
            % Return:
            %  - none
            
            assert(~isempty(this.delegate),'You need to specify a delegate before starting the socket');
            this.mainLoop();
            
        end
        
        function stop(this)
            % Activates server stop toggle.
            %
            % Parameter:
            %  - none
            %
            % Return:
            %  - none
            
            this.stopServer = true;
        end
        
        function response = sendRequest(this,content)
            % Sends request to socket server.
            %
            % Parameter:
            %  - content: Struct argument; socket request message.
            %
            % Return:
            %  - response: Struct argument; socket return message.
            
            % Serialize and write the request
            id = nextRequestID(this);
            request = this.serialize(content,0,id);
            write(this.socket,request);
            
            response = {};
            
            % Wait for response message
            while isempty(response)
                
                messages = this.readSocket();
                
                % Search for related resonse in messages
                for idx = 1:numel(messages)
                    [~,response_id,content] = this.deserialize(messages{idx});
                    
                    % Message found
                    if (response_id == id)
                        response = content;
                        messages(idx) = [];
                        break;
                    end
                end
                
                this.messageCue = horzcat(this.messageCue,messages);
                
            end
        end
        
    end
    
    methods (Static)
        
        function header = makeHeader(message)
            % Creates byte header for socket message.
            %
            % Parameter:
            %  - message: String argument; socket message.
            %
            % Return:
            %  - header: Byte object; message size;
            
            sizeMessage = numel(message);
            header = typecast(swapbytes(uint32(sizeMessage)),'uint8');
            
        end
        
    end
    
end
