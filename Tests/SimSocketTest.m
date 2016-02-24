classdef SimSocketTest < matlab.unittest.TestCase & MosaikAPI.SimSocketDelegate
    %SIMSOCKETTEST Unit Test for the SimSocket
    
    
    properties
        messages = {}
        socket
        numberOfMessages = 0
    end
    
    
    methods
        function response = simSocketReceivedRequest(this,message)
            this.messages{end+1} = message;
            response = 'ok';
            if numel(this.messages) >= this.numberOfMessages
                this.socket.stop;
            end
        end
        
        function tcpCommunicationReceive(this,serverMessages,varargin)
            
            this.messages = {};
            this.numberOfMessages = numel(serverMessages);
            
            option = '-s';
            if numel(varargin)>0
                option = varargin{1};
            end
            
            serverMessages = cellfun(@(x) [' ' x],serverMessages,'UniformOutput',false);
            
            port = randi([10000 65000],1,1);
            
            system(['start /B /min python sendingServer.py' ' ' num2str(port) ' ' option serverMessages{:}]);
            this.socket = MosaikAPI.SimSocket('localhost',port,'delegate',this);
            this.socket.start();
            this.socket = [];
            
        end
        
        
        function [len,out,varargout] = tcpCommunicationSend(this,data,varargin)
            
            answer = '';
            option = '';
            
            if numel(varargin)>0
                answer = varargin{1};
            end
            
            if numel(varargin)>1
                option = varargin{2};
            end
            
            
            t = timer;
            t.StartDelay = 0.1;
            t.TimerFcn  = @(myTimerObj, thisEvent) this.tcpCommunicationTimerFunction(myTimerObj,data);
            start(t)
            [~,cmdout] = system(['python receivingServer.py ' option ' ' answer]);
            if nargout > 2
                varargout{1} = t.UserData;
            end
            delete(t);
            cmdout = str2num(cmdout);
            len = double(swapbytes(typecast(uint8(cmdout(1:4)), 'uint32')));
            out = char(cmdout(5:end));
            
        end
        
        function tcpCommunicationTimerFunction(~,myTimerObj,data)
            
            s = MosaikAPI.SimSocket('localhost',8000);
            response = s.sendRequest(data);
            
            set(myTimerObj,'UserData',response);
            
        end
        
        
    end
    
    
    methods (Test)
        
        
        function receiveSampleStopMessage(this)
            
            serverMessage = '"[0, 0, [\"stop\", [], {}]]"';
            this.tcpCommunicationReceive({serverMessage});
            
            this.verifyEqual(this.messages{1}{1},'stop');
            this.verifyEmpty(this.messages{1}{2});
            this.verifyEmpty(this.messages{1}{3});
        end
        
        function receiveSampleStepMessageWithNoInputs(this)
            
            serverMessage = '"[0, 0, [\"step\", [0, {}], {}]]"';
            this.tcpCommunicationReceive({serverMessage});
            
            this.verifyEqual(this.messages{1}{1},'step');
            this.verifyEqual(this.messages{1}{2},0);
            this.verifyEmpty(this.messages{1}{3});
            
        end
        
        function receiveSampleStepMessageWithInputs(this)
            
            serverMessage = '"[0, 2, [\"step\", [0, {\"Collector\": {\"val\": {\"Matlab-0.Model_0\": 3}, \"delta\": {\"Matlab-0.Model_0\": 1}}}], {}]]"';
            this.tcpCommunicationReceive({serverMessage});
            
            this.verifyEqual(this.messages{1}{1},'step');
            this.verifyEqual(this.messages{1}{2}{1},0);
            this.verifyEqual(this.messages{1}{2}{2},...
                struct('Collector',struct('val',struct('Matlab_0x2D_0_0x2E_Model_0',3),'delta',struct('Matlab_0x2D_0_0x2E_Model_0',1))));
            this.verifyEmpty(this.messages{1}{3});
            
        end
        
        function receiveSampleInitMethodsWithNoOptions(this)
            serverMessage = '"[0, 0, [\"init\", [\"Monitor-0\"], {}]]"';
            this.tcpCommunicationReceive({serverMessage});
            
            this.verifyEqual(this.messages{1}{1},'init');
            this.verifyEqual(this.messages{1}{2},{'Monitor-0'});
            this.verifyEmpty(this.messages{1}{3});
            
        end
        
        
        function receiveSampleInitMethodsWithWithOptions(this)
            serverMessage = '"[0, 0, [\"init\", [\"Monitor-0\"], {\"step_size\": 1}]]"';
            this.tcpCommunicationReceive({serverMessage});
            
            this.verifyEqual(this.messages{1}{1},'init');
            this.verifyEqual(this.messages{1}{2},{'Monitor-0'});
            this.verifyEqual(this.messages{1}{3},...
                struct('step_size',1));
            
        end
        
        function receiveSampleCreateMethod(this)
            serverMessage = '"[0, 1, [\"create\", [1, \"Collector\"], {}]]"';
            this.tcpCommunicationReceive({serverMessage});
            
            this.verifyEqual(this.messages{1}{1},'create');
            this.verifyEqual(this.messages{1}{2},{1,'Collector'});
            this.verifyEmpty(this.messages{1}{3});
            
        end
        
        function receiveSampleCreateMethodWithOptions(this)
            
            serverMessage = '"[0, 1, [\"create\", [1, \"Model\"], {\"init_value\": 2}]]"';
            this.tcpCommunicationReceive({serverMessage});
            
            this.verifyEqual(this.messages{1}{1},'create');
            this.verifyEqual(this.messages{1}{2},{1,'Model'});
            this.verifyEqual(this.messages{1}{3},...
                struct('init_value',2));
            
        end
        
        function receiveSampleGetDateMethod(this)
            
            serverMessage = '"[0, 3, [\"get_data\", [{\"Model_0\": [\"val\", \"delta\"]}], {}]]"';
            this.tcpCommunicationReceive({serverMessage});
            
            this.verifyEqual(this.messages{1}{1},'get_data');
            this.verifyEqual(this.messages{1}{2}{1},...
                struct('Model_0',{{'val','delta'}}));
            this.verifyEmpty(this.messages{1}{3});
            
        end
        
        
        function receiveLongMessage(this)
            text = num2str(randi(9,2^12,1))';
            serverMessage = ['"[0, 2, [\"a' text '\", [], {}]]"'];
            
            this.tcpCommunicationReceive({serverMessage});
            this.verifyEqual(this.messages{1}{1},['a' text]);
            this.verifyEmpty(this.messages{1}{2});
            this.verifyEmpty(this.messages{1}{3});
        end
        
        
        function receiveMultibleMessages(this)
            text1 = num2str(randi(9,50,1))';
            text2 = num2str(randi(9,50,1))';
            text3 = num2str(randi(9,50,1))';
            text4 = num2str(randi(9,50,1))';
            text5 = num2str(randi(9,50,1))';
            serverMessages{1} = ['"[0, 2, [\"a' text1 '\", [], {}]]"'];
            serverMessages{2} = ['"[0, 3, [\"a' text2 '\", [], {}]]"'];
            serverMessages{3} = ['"[0, 4, [\"a' text3 '\", [], {}]]"'];
            serverMessages{4} = ['"[0, 5, [\"a' text4 '\", [], {}]]"'];
            serverMessages{5} = ['"[0, 6, [\"a' text5 '\", [], {}]]"'];
            
            this.tcpCommunicationReceive(serverMessages);
            
            this.verifyEqual(this.messages{1}{1},['a' text1]);
            this.verifyEqual(this.messages{2}{1},['a' text2]);
            this.verifyEqual(this.messages{3}{1},['a' text3]);
            this.verifyEqual(this.messages{4}{1},['a' text4]);
            this.verifyEqual(this.messages{5}{1},['a' text5]);
            this.verifyEmpty(this.messages{1}{2});
            this.verifyEmpty(this.messages{1}{3});
            this.verifyEmpty(this.messages{2}{2});
            this.verifyEmpty(this.messages{2}{3});
            this.verifyEmpty(this.messages{3}{2});
            this.verifyEmpty(this.messages{3}{3});
            this.verifyEmpty(this.messages{4}{2});
            this.verifyEmpty(this.messages{4}{3});
            this.verifyEmpty(this.messages{5}{2});
            this.verifyEmpty(this.messages{5}{3});
        end
        
        function receiveMultibleCombinedMessages(this)
            text1 = num2str(randi(9,50,1))';
            text2 = num2str(randi(9,50,1))';
            text3 = num2str(randi(9,50,1))';
            text4 = num2str(randi(9,50,1))';
            text5 = num2str(randi(9,50,1))';
            serverMessages{1} = ['"[0, 2, [\"a' text1 '\", [], {}]]"'];
            serverMessages{2} = ['"[0, 3, [\"a' text2 '\", [], {}]]"'];
            serverMessages{3} = ['"[0, 4, [\"a' text3 '\", [], {}]]"'];
            serverMessages{4} = ['"[0, 5, [\"a' text4 '\", [], {}]]"'];
            serverMessages{5} = ['"[0, 6, [\"a' text5 '\", [], {}]]"'];
            
            this.tcpCommunicationReceive(serverMessages,'-c');
            
            this.verifyEqual(this.messages{1}{1},['a' text1]);
            this.verifyEqual(this.messages{2}{1},['a' text2]);
            this.verifyEqual(this.messages{3}{1},['a' text3]);
            this.verifyEqual(this.messages{4}{1},['a' text4]);
            this.verifyEqual(this.messages{5}{1},['a' text5]);
            this.verifyEmpty(this.messages{1}{2});
            this.verifyEmpty(this.messages{1}{3});
            this.verifyEmpty(this.messages{2}{2});
            this.verifyEmpty(this.messages{2}{3});
            this.verifyEmpty(this.messages{3}{2});
            this.verifyEmpty(this.messages{3}{3});
            this.verifyEmpty(this.messages{4}{2});
            this.verifyEmpty(this.messages{4}{3});
            this.verifyEmpty(this.messages{5}{2});
            this.verifyEmpty(this.messages{5}{3});
        end
        
        function receiveMultibleSplitMessages(this)
            
            for idx = [1:10]
                text1 = num2str(randi(9,50,1))';
                text2 = num2str(randi(9,50,1))';
                text3 = num2str(randi(9,50,1))';
                text4 = num2str(randi(9,50,1))';
                text5 = num2str(randi(9,50,1))';
                serverMessages{1} = ['"[0, 2, [\"a' text1 '\", [], {}]]"'];
                serverMessages{2} = ['"[0, 3, [\"a' text2 '\", [], {}]]"'];
                serverMessages{3} = ['"[0, 4, [\"a' text3 '\", [], {}]]"'];
                serverMessages{4} = ['"[0, 5, [\"a' text4 '\", [], {}]]"'];
                serverMessages{5} = ['"[0, 6, [\"a' text5 '\", [], {}]]"'];
                
                this.tcpCommunicationReceive(serverMessages,'-s');
                
                this.verifyEqual(this.messages{1}{1},['a' text1]);
                this.verifyEqual(this.messages{2}{1},['a' text2]);
                this.verifyEqual(this.messages{3}{1},['a' text3]);
                this.verifyEqual(this.messages{4}{1},['a' text4]);
                this.verifyEqual(this.messages{5}{1},['a' text5]);
                this.verifyEmpty(this.messages{1}{2});
                this.verifyEmpty(this.messages{1}{3});
                this.verifyEmpty(this.messages{2}{2});
                this.verifyEmpty(this.messages{2}{3});
                this.verifyEmpty(this.messages{3}{2});
                this.verifyEmpty(this.messages{3}{3});
                this.verifyEmpty(this.messages{4}{2});
                this.verifyEmpty(this.messages{4}{3});
                this.verifyEmpty(this.messages{5}{2});
                this.verifyEmpty(this.messages{5}{3});
            end
        end
        
        
        
        
        function sendStructData(this)
            
            data.a = 1;
            data.b = 'test';
            data.c = {'a','b','c'};
            data.d = {'a',[]};
            data.e.a = 1;
            data.e.b = 2;
            data.f = {'a'};
            
            res = '[0,1,{"a": 1,"b": "test","c": ["a","b","c"],"d": ["a"],"e": {"a": 1,"b": 2},"f": ["a"]}]';
            
            [len,out,response] = this.tcpCommunicationSend(data);
            
            disp(response)
            
            this.verifyEqual(len,numel(out));
            this.verifyEqual(out,res);
            
            
        end
        
        function sendScalarArrayData(this)
            
            data = {struct('a',true),[]};
            [len,out] = this.tcpCommunicationSend(data);
            
            res = '[0,1,[{"a": true}]]';
            
            this.verifyEqual(len,numel(out));
            this.verifyEqual(out,res);
            
        end
        
        function sendArrayData(this)
            
            data = {struct('a',1),struct('a',2)};
            [len,out] = this.tcpCommunicationSend(data);
            
            res = '[0,1,[{"a": 1},{"a": 2}]]';
            
            this.verifyEqual(len,numel(out));
            this.verifyEqual(out,res);
            
        end
        
        function getAnswerFromRequest(this)
            
            data = {'get_answer',{},struct};
            answer = '"[\"answer\", [], {}]"';
            [len,out,response] = this.tcpCommunicationSend(data,answer);
            
            res = '[0,1,["get_answer",[],{}]]';
                        
            this.verifyEqual(len,numel(out));
            this.verifyEqual(out,res);
            this.verifyEqual(response{1},'answer');
            this.verifyEmpty(response{2});
            this.verifyEmpty(response{3});
        end
        
        function getMulitAnswersFromRequest(this)
            
            data = {'get_answer',{},struct};
            answer = '"[\"answer\", [], {}]"';
            [len,out,response] = this.tcpCommunicationSend(data,answer,'-c');
            
            res = '[0,1,["get_answer",[],{}]]';
                        
            this.verifyEqual(len,numel(out));
            this.verifyEqual(out,res);
            this.verifyEqual(response{1},'answer');
            this.verifyEmpty(response{2});
            this.verifyEmpty(response{3});
        end
        
        function getSplitMulitAnswersFromRequest(this)
            
            data = {'get_answer',{},struct};
            answer = '"[\"answer\", [], {}]"';
            [len,out,response] = this.tcpCommunicationSend(data,answer,'-s');
            
            res = '[0,1,["get_answer",[],{}]]';
                        
            this.verifyEqual(len,numel(out));
            this.verifyEqual(out,res);
            this.verifyEqual(response{1},'answer');
            this.verifyEmpty(response{2});
            this.verifyEmpty(response{3});
        end
        
        function getUnorderdMulitAnswersFromRequest(this)
            
            data = {'get_answer',{},struct};
            answer = '"[\"answer\", [], {}]"';
            [len,out,response] = this.tcpCommunicationSend(data,answer,'-o');
            
            res = '[0,1,["get_answer",[],{}]]';
                        
            this.verifyEqual(len,numel(out));
            this.verifyEqual(out,res);
            this.verifyEqual(response{1},'answer');
            this.verifyEmpty(response{2});
            this.verifyEmpty(response{3});
        end
        
        
    end
    
end

