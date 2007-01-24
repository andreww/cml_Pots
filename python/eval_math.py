import lxml.etree

namespaces = {'c':'http://www.xml-cml.org/schema',
              'm':'http://www.w3.org/1998/Math/MathML'}


def evalMath(function, depth):
    # expecting a single apply to process...
    
    print " "*depth + "In evalMath====="   
    print " "*depth + "Looking at: " 
    print function
    for element in function:
        ciapply = element.xpath("m:ci[m:apply]", namespaces)
        if len(ciapply) != 0:
            for value in ciapply:
                print " "*depth + "Applying a ci apply"
                evalMath(value, depth + 1)
                print "BACK"
                # add result to dict
            continue
        cn = element.xpath("m:cn/text()", namespaces)
        if len(cn) != 0:
            for value in cn:
                print " "*depth + "A cn found for processing:" + value
                # Turn number into a number and add it to dict
            continue 
        ci = element.xpath("m:ci/text()", namespaces)
        if len(ci) != 0:
            for value in ci:
                print " "*depth + "ci found for processing: " + value
                print element
            continue
    print depth*" " + "=============="
    return ()
#        print element 
      


# Load in XML document, extract any MathML
docRoot = lxml.etree.parse(source='../buck.xml')
math = docRoot.xpath("//m:math", namespaces)[0]
evalMath(math, 0)
