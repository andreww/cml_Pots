import lxml.etree

namespaces = {'c':'http://www.xml-cml.org/schema',
              'm':'http://www.w3.org/1998/Math/MathML'}

def evalApply(function):
    op = ''
    args = []
    mml = '{http://www.w3.org/1998/Math/MathML}'
    # Get children of the apply element:
    function = function.getchildren()
    print function[0].tag
    print len(function)
    if len(function) == 0:
        raise "no args!"
    elif len(function) == 1:
        raise "no args!"
    elif len(function) == 2:
        if (function[0].tag.find(mml + 'minus') == 0):
            print "Handaling a minus"
            apply = function[1].find(mml+'apply')
            print apply
            if apply != None:
                print "Recursive!"
                arg1 = evalApply(apply)
            elif (function[1].tag.find(mml+'ci') == 0):
                arg1 = function[1].text
            elif (function[1].tag.find(mml+'cn') == 0):
                arg1 = function[1].text
            else:
                raise "Bombed out in minus"
            return ("-" + arg1)
        elif (function[0].tag.find(mml + 'exp') == 0):
            apply = function[1].find(mml+'apply')
            print apply
            if apply != None:
                arg1 = evalApply(apply)
            elif (function[1].tag.find(mml+'ci') == 0):
                arg1 = function[1].text
            elif (function[1].tag.find(mml+'cn') == 0):
                arg1 = function[1].text
            else:
                raise "Bombed out in minus"
            return ("exp(" + arg1 + ")")
        else:
            raise "Unknown unary op"

    elif len(function) == 3:
        print "A binary op"
        if (function[0].tag.find(mml + 'minus') == 0):
            print "Handaling a minus"
            apply = function[1].find(mml+'apply')
            print apply
            if apply != None:
                print "Recursive!"
                arg1 = evalApply(apply)
            elif (function[1].tag.find(mml+'ci') == 0):
                arg1 = function[1].text
            elif (function[1].tag.find(mml+'cn') == 0):
                arg1 = function[1].text
            else:
                raise "Bombed out in minus"
            apply = function[2].find(mml+'apply')
            if apply != None:
                arg2 = evalApply(apply)
            elif (function[2].tag.find(mml+'ci') == 0):
                arg2 = function[2].text
            elif (function[2].tag.find(mml+'cn') == 0):
                arg2 = function[2].text
            else:
                raise "Bombed out in minus"
            return ("(" + arg1 + "-" + arg2 +")")
        if (function[0].tag.find(mml + 'times') == 0):
            apply = function[1].find(mml+'apply')
            print apply
            if apply != None:
                arg1 = evalApply(apply)
            elif (function[1].tag.find(mml+'ci') == 0):
                arg1 = function[1].text
            elif (function[1].tag.find(mml+'cn') == 0):
                arg1 = function[1].text
            else:
                raise "Bombed out "
            apply = function[2].find(mml+'apply')
            if apply != None:
                arg2 = evalApply(apply)
            elif (function[2].tag.find(mml+'ci') == 0):
                arg2 = function[2].text
            elif (function[2].tag.find(mml+'cn') == 0):
                arg2 = function[2].text
            else:
                raise "Bombed out "
            return ("(" + arg1 + "*" + arg2 +")")
        if (function[0].tag.find(mml + 'divide') == 0):
            apply = function[1].find(mml+'apply')
            if apply != None:
                arg1 = evalApply(apply)
            elif (function[1].tag.find(mml+'ci') == 0):
                arg1 = function[1].text
            elif (function[1].tag.find(mml+'cn') == 0):
                arg1 = function[1].text
            else:
                raise "Bombed out "
            apply = function[2].find(mml+'apply')
            if apply != None:
                arg2 = evalApply(apply)
            elif (function[2].tag.find(mml+'ci') == 0):
                arg2 = function[2].text
            elif (function[2].tag.find(mml+'cn') == 0):
                arg2 = function[2].text
            else:
                raise "Bombed out "
            return ("(" + arg1 + "/" + arg2 +")")
        if (function[0].tag.find(mml + 'power') == 0):
            apply = function[1].find(mml+'apply')
            if apply != None:
                arg1 = evalApply(apply)
            elif (function[1].tag.find(mml+'ci') == 0):
                arg1 = function[1].text
            elif (function[1].tag.find(mml+'cn') == 0):
                arg1 = function[1].text
            else:
                raise "Bombed out "
            apply = function[2].find(mml+'apply')
            if apply != None:
                arg2 = evalApply(apply)
            elif (function[2].tag.find(mml+'ci') == 0):
                arg2 = function[2].text
            elif (function[2].tag.find(mml+'cn') == 0):
                arg2 = function[2].text
            else:
                raise "Bombed out "
            return ("(" + arg1 + "^" + arg2 +")")
    
    


    return()




def evalMath(function, depth):
    # expecting a single apply to process...
    op = ''
    args = []
    print " "*depth + "In evalMath====="   
    print " "*depth + "Looking at: " 
#    print function
    for element in function:
        print " "*depth + element.tag 
        print " "*depth + "looping"
        ops = element.xpath("m:minus", namespaces)
        if len(ops) == 1:
            print depth*" " + "minus found"
            op = '-'
        ops = element.xpath("m:exp", namespaces)
        if len(ops) == 1:
            print depth*" " + "exp found"
            op = 'exp'
        ops = element.xpath("m:times", namespaces)
        if len(ops) == 1:
            print depth*" " + "times found"
            op = '*'
        ops = element.xpath("m:power", namespaces)
        if len(ops) == 1:
            print depth*" " + "power found"
            op = '^'
        ops = element.xpath("m:divide", namespaces)
        if len(ops) == 1:
            print depth*" " + "divide found"
            op = '/'
#            continue
#        cn = element.xpath("m:cn/text()", namespaces)
#        if len(cn) != 0:
#            for value in cn:
#                print " "*depth + "A cn found for processing:" + value
#                args.append(value)
                # Turn number into a number and add it to dict
#            continue 
#        ci = element.xpath("normalize-space(m:ci/text())", namespaces)
        ci = element.xpath("m:ci[not(m:apply)]/text()|m:cn/text()", namespaces)
        if (len(ci) != 0):
            for value in ci:
                if not value.isspace():
                    print " "*depth + "ci found for processing: '" + value +"'"
                    args.append(value)
#                print element
#            continue
# NOTE: Bugfix needed - catches apply fist by the looks of it...
# do I need to combine ciapply and ci logic?
        ciapply = element.xpath("m:ci[m:apply]", namespaces)
        if len(ciapply) != 0:
            for value in ciapply:
                print " "*depth + "Applying a ci apply"
                args.append(evalMath(value, depth + 1))
                print "BACK"
                # add result to dict
#            continue
#        ci = None
#        cn = None
#        ciapply = None
#        ops = None
    print depth*" " + "=============="
    if len(args) == 0:
        raise "No args"
    elif len(args) == 1:
        if op == '-':
            return ('-' + args[0] )
        elif op == 'exp':
            return ('exp(' + args[0] + ')' )
        else:
            raise "Unary op not known"
    elif len(args) == 2:
        if op == '-':
            return ('(' + args[0] + '-' + args[1] + ')')
        elif op == '*':
            return ('(' + args[0] + '*' + args[1] + ')')
        elif op == '/':
            return ('(' + args[0] + '/' + args[1] + ')')
        elif op == '^':
            return ('(' + args[0] + '^' + args[1] + ')')
    raise "Dropped off the end"
#        print element 
      


# Load in XML document, extract any MathML
docRoot = lxml.etree.parse(source='../buck.xml')
math = docRoot.xpath("//m:math", namespaces)[0]
result = evalMath(math, 0)
print result
math = docRoot.xpath("//m:math/m:apply", namespaces)[0]
result = evalApply(math)
print result
