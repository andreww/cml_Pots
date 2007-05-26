import lxml.etree
import math

namespaces = {'c':'http://www.xml-cml.org/schema',
              'm':'http://www.w3.org/1998/Math/MathML'}
class mathml:

    def __init__(self, xml, parameters):
        self.xml = xml
        self.expression = ''
        self.parameters = parameters
        self.boundVars = []

    def asPythonFunction(self):
        print "In asPythonFunction"
        print self.boundVars
        funcstring = "fun = lambda " + self.boundVars[0] + ": " + self.expression
        exec (funcstring)
        ## eval("def fun(" + self.boundVars[0] + "): return "+self.expression)
        ##f = compile("def fun(" + self.boundVars[0] + "): return "+self.expression+ "\n", '<string>', 'exec')
        ##eval(f)
        return fun


    def parseMML(self):
        elements = self.xml.getchildren()
        if len(elements) != 1:
            raise "Can only have one expression in a math fragment"
        if elements[0].tag.find('{http://www.w3.org/1998/Math/MathML}lambda') == 0:
            child = mathml(elements[0], self.parameters)
            self.expression = child.evalLambda()
            self.boundVars = child.boundVars
        elif elements[0].tag.find('{http://www.w3.org/1998/Math/MathML}apply') == 0:
            child = mathml(elements[0], self.parameters)
            self.expression = child.evalApply()
        else:
            raise "Could not parse Math"
        return()

    def evalLambda(self):
        mml = '{http://www.w3.org/1998/Math/MathML}'
        
        elements = self.xml.getchildren()
        if len(elements) == 0:
           raise "No elements"
        elif len(elements) == 1:
           raise "only one element"
        elif len(elements) >= 2:
           bvar = elements[0]
           ci = bvar.getchildren()
           var = [ci[0].text]
           self.boundVars = self.boundVars + var
           apply = elements[-1]
           if apply != None:
               if apply.tag != (mml + 'apply'):
                   raise "ERROR"
               else:
                   self.expression = mathml(apply, self.parameters)
                   self.expression = self.expression.evalApply()
                  # self.expression = self.eval(apply)
           else:
               raise "apply not found in evalLambda"
      
        else:
           raise "error in evalLambda"


        return self.expression

        

    def evalApply(self):
        function = self.xml
        op = ''
        args = []
        mml = '{http://www.w3.org/1998/Math/MathML}'
        # Get children of the apply element:
        function = function.getchildren()
        if len(function) == 0:
            raise "no args!"
        elif len(function) == 1:
            raise "no args!"
        elif len(function) == 2:
            if (function[0].tag.find(mml + 'minus') == 0):
                apply = function[1].find(mml+'apply')
                if apply != None:
                    arg1 = mathml(apply, self.parameters)
                    arg1 = arg1.evalApply()
                elif (function[1].tag.find(mml+'ci') == 0):
                    arg1 = self.parameters[function[1].text]
                elif (function[1].tag.find(mml+'cn') == 0):
                    arg1 = function[1].text
                else:
                    raise "Bombed out in minus"
                return ("-" + arg1)
            elif (function[0].tag.find(mml + 'exp') == 0):
                apply = function[1].find(mml+'apply')
                if apply != None:
                    arg1 = mathml(apply, self.parameters)
                    arg1 = arg1.evalApply()
                elif (function[1].tag.find(mml+'ci') == 0):
                    arg1 = self.parameters[function[1].text]
                elif (function[1].tag.find(mml+'cn') == 0):
                    arg1 = function[1].text
                else:
                    raise "Bombed out in minus"
                return ("math.exp(" + arg1 + ")")
            else:
                raise "Unknown unary op"

        elif len(function) == 3:
            if (function[0].tag.find(mml + 'minus') == 0):
                apply = function[1].find(mml+'apply')
                if apply != None:
                    arg1 = mathml(apply, self.parameters)
                    arg1 = arg1.evalApply()
                elif (function[1].tag.find(mml+'ci') == 0):
                    arg1 = self.parameters[function[1].text]
                elif (function[1].tag.find(mml+'cn') == 0):
                    arg1 = function[1].text
                else:
                    raise "Bombed out in minus"
                apply = function[2].find(mml+'apply')
                if apply != None:
                    arg2 = mathml(apply, self.parameters)
                    arg2 = arg2.evalApply()
                elif (function[2].tag.find(mml+'ci') == 0):
                    arg2 = self.parameters[function[2].text]
                elif (function[2].tag.find(mml+'cn') == 0):
                    arg2 = function[2].text
                else:
                    raise "Bombed out in minus"
                return ("(" + arg1 + "-" + arg2 +")")
            if (function[0].tag.find(mml + 'times') == 0):
                apply = function[1].find(mml+'apply')
                if apply != None:
                    arg1 = mathml(apply, self.parameters)
                    arg1 = arg1.evalApply()
                elif (function[1].tag.find(mml+'ci') == 0):
                    arg1 = self.parameters[function[1].text]
                elif (function[1].tag.find(mml+'cn') == 0):
                    arg1 = function[1].text
                else:
                    raise "Bombed out "
                apply = function[2].find(mml+'apply')
                if apply != None:
                    arg2 = mathml(apply, self.parameters)
                    arg2 = arg2.evalApply()
                elif (function[2].tag.find(mml+'ci') == 0):
                    arg2 = self.parameters[function[2].text]
                elif (function[2].tag.find(mml+'cn') == 0):
                    arg2 = function[2].text
                else:
                    raise "Bombed out "
                return ("(" + arg1 + "*" + arg2 +")")
            if (function[0].tag.find(mml + 'divide') == 0):
                apply = function[1].find(mml+'apply')
                if apply != None:
                    arg1 = mathml(apply, self.parameters)
                    arg1 = arg1.evalApply()
                elif (function[1].tag.find(mml+'ci') == 0):
                    arg1 = self.parameters[function[1].text]
                elif (function[1].tag.find(mml+'cn') == 0):
                    arg1 = function[1].text
                else:
                    raise "Bombed out "
                apply = function[2].find(mml+'apply')
                if apply != None:
                    arg2 = mathml(apply, self.parameters)
                    arg2 = arg2.evalApply()
                elif (function[2].tag.find(mml+'ci') == 0):
                    arg2 = self.parameters[function[2].text]
                elif (function[2].tag.find(mml+'cn') == 0):
                    arg2 = function[2].text
                else:
                    raise "Bombed out "
                return ("(" + arg1 + "/" + arg2 +")")
            if (function[0].tag.find(mml + 'power') == 0):
                apply = function[1].find(mml+'apply')
                if apply != None:
                    arg1 = mathml(apply, self.parameters)
                    arg1 = arg1.evalApply()
                elif (function[1].tag.find(mml+'ci') == 0):
                    arg1 = self.parameters[function[1].text]
                elif (function[1].tag.find(mml+'cn') == 0):
                    arg1 = function[1].text
                else:
                    raise "Bombed out "
                apply = function[2].find(mml+'apply')
                if apply != None:
                    arg2 = mathml(apply, self.parameters)
                    arg2 = arg2.evalApply()
                elif (function[2].tag.find(mml+'ci') == 0):
                    arg2 = self.parameters[function[2].text]
                elif (function[2].tag.find(mml+'cn') == 0):
                    arg2 = function[2].text
                else:
                    raise "Bombed out "
                return ("math.pow(" + arg1 + "," + arg2 +")")
        raise "Dropped off parser!"
    
 
# TODO - add testing methods here... need to be able to refactor
# Load in XML document, extract any MathML
#docRoot = lxml.etree.parse(source='../buck.xml')
#math = docRoot.xpath("//m:math/m:apply", namespaces)[0]
#result = mathml(math)
#print result.evalApply()
