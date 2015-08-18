classdef SimSocketDelegate < handle
    %SIMSOCKETDELEGATE 
    %   Abstract delegate class for SimSocket
    %
    %   Required delegate methods are:
    %    - response = simSocketReceivedRequest(this,simSocket,request);
    %
    
    methods (Abstract)
        delegate(this,simSocket,request);
    end
    
end

