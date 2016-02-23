classdef SimSocketTest < matlab.unittest.TestCase & MosaikAPI.SimSocketDelegate
    %SIMSOCKETTEST Unit Test for the SimSocket
    
    
    properties
       message
       socket
    end
    
    
    methods
        function response = simSocketReceivedRequest(this,message)
           this.message = message;
           response = 'ok';
           this.socket.stop;
        end
        
        function tcpCommunicationReceive(this,serverMessage)
            
            system(['start /B /min python sendingServer.py' ' ' serverMessage]);
            this.socket = MosaikAPI.SimSocket('localhost',8000,'delegate',this);
            this.socket.start();
            this.socket = [];
            
        end
        
        
        function [len,out] = tcpCommunicationSend(~,data)
           
            t = timer;
            t.StartDelay = 0.1;
            t.TimerFcn  = @(myTimerObj, thisEvent)MosaikAPI.SimSocket('localhost',8000).sendRequest(data);
            start(t)
            [~,cmdout] = system('python receivingServer.py');
            delete(t);
            cmdout = str2num(cmdout);
            len = double(swapbytes(typecast(uint8(cmdout(1:4)), 'uint32')));
            out = char(cmdout(5:end));
        end
        
    end
   
    
    methods (Test)
        
        
        function receiveSampleStopMessage(this)
            
            serverMessage = '"[0, 0, [\"stop\", [], {}]]"';
            this.tcpCommunicationReceive(serverMessage);
            
            this.verifyEqual(this.message{1},'stop');
            this.verifyEmpty(this.message{2});
            this.verifyEmpty(this.message{3});           
        end
        
        function receiveSampleStepMessageWithNoInputs(this)
            
            serverMessage = '"[0, 0, [\"step\", [0, {}], {}]]"';
            this.tcpCommunicationReceive(serverMessage);
            
            this.verifyEqual(this.message{1},'step');
            this.verifyEqual(this.message{2},0);
            this.verifyEmpty(this.message{3});           
            
        end
        
        function receiveSampleStepMessageWithInputs(this)
            
            serverMessage = '"[0, 2, [\"step\", [0, {\"Collector\": {\"val\": {\"Matlab-0.Model_0\": 3}, \"delta\": {\"Matlab-0.Model_0\": 1}}}], {}]]"';
            this.tcpCommunicationReceive(serverMessage);
            
            this.verifyEqual(this.message{1},'step');
            this.verifyEqual(this.message{2}{1},0);
            this.verifyEqual(this.message{2}{2},...
                struct('Collector',struct('val',struct('Matlab_0x2D_0_0x2E_Model_0',3),'delta',struct('Matlab_0x2D_0_0x2E_Model_0',1))));
            this.verifyEmpty(this.message{3});           
            
        end
        
        function receiveSampleInitMethodsWithNoOptions(this)
            serverMessage = '"[0, 0, [\"init\", [\"Monitor-0\"], {}]]"';
            this.tcpCommunicationReceive(serverMessage);
            
            this.verifyEqual(this.message{1},'init');
            this.verifyEqual(this.message{2},{'Monitor-0'});
            this.verifyEmpty(this.message{3});     
            
        end
        
        
        function receiveSampleInitMethodsWithWithOptions(this)
            serverMessage = '"[0, 0, [\"init\", [\"Monitor-0\"], {\"step_size\": 1}]]"';
            this.tcpCommunicationReceive(serverMessage);
            
            this.verifyEqual(this.message{1},'init');
            this.verifyEqual(this.message{2},{'Monitor-0'});
            this.verifyEqual(this.message{3},...
                struct('step_size',1));
            
        end
        
        function receiveSampleCreateMethod(this)
            serverMessage = '"[0, 1, [\"create\", [1, \"Collector\"], {}]]"';
            this.tcpCommunicationReceive(serverMessage);
            
            this.verifyEqual(this.message{1},'create');
            this.verifyEqual(this.message{2},{1,'Collector'});
            this.verifyEmpty(this.message{3});     
            
        end
        
        function receiveSampleCreateMethodWithOptions(this)
            
            serverMessage = '"[0, 1, [\"create\", [1, \"Model\"], {\"init_value\": 2}]]"';
            this.tcpCommunicationReceive(serverMessage);
            
            this.verifyEqual(this.message{1},'create');
            this.verifyEqual(this.message{2},{1,'Model'});
            this.verifyEqual(this.message{3},...
                struct('init_value',2));   
            
        end
        
        function receiveSampleGetDateMethod(this)
            
            serverMessage = '"[0, 3, [\"get_data\", [{\"Model_0\": [\"val\", \"delta\"]}], {}]]"';
            this.tcpCommunicationReceive(serverMessage);
            
            this.verifyEqual(this.message{1},'get_data');
            this.verifyEqual(this.message{2}{1},...
                struct('Model_0',{{'val','delta'}}));
            this.verifyEmpty(this.message{3});     
            
        end
        
        
        function receiveLongMessage(this)
            text = num2str(randi(9,2^12,1))';
            serverMessage = ['"[0, 2, [\"a' text '\", [], {}]]"'];
            
            this.tcpCommunicationReceive(serverMessage);
            this.verifyEqual(this.message{1},['a' text]);
            this.verifyEmpty(this.message{2});
            this.verifyEmpty(this.message{3});  
        end
        
        
        function sendStructData(this)
           
            data.a = 1;
            data.b = 'test';
            data.c = {'a','b','c'};
            data.d = {'a',[]};
            data.e.a = 1;
            data.e.b = 2;
            
            res = '[0,1,{"a": 1,"b": "test","c": ["a","b","c"],"d": ["a"],"e": {"a": 1,"b": 2}}]';
            
            [len,out] = this.tcpCommunicationSend(data);
            
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
        
    end
    
end

