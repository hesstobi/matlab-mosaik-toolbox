classdef SimSocketDelegate
    %SIMSOCKETDELEGATE 
    %   Abstract delegate class for SimSocket
    %
    %   Requiered delegate methods are:
    %    - response = simSocketReceivedRequest(this,simSocket,request);
    %
    
    methods (Abstract)
        simSocketReceivedRequest(this,simSocket,request);
    end
    
end

