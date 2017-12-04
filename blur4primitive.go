package main

import (
    "flag"
    "fmt"
    "os"
    "encoding/xml"
)

func main() {
    
    if len(os.Args) == 1 {
        usage(os.Args[0])
        return
    }

    deviation := flag.Uint("d", 12, "Gausian deviation")
    help := flag.Bool("h", false, "Prints this help")
    flag.Parse()
    srcSvgName := os.Args[len(os.Args) - 1]
    
    if *help {
        usage(os.Args[0])
        return
    }
    
	xmlFile, err := os.Open(srcSvgName)
	if err != nil {
		fmt.Println("Error opening file:", err)
		return
	}
	defer xmlFile.Close()

	decoder := xml.NewDecoder(xmlFile)
    openG := 0

	fmt.Fprintf(os.Stdout, "<?xml version='1.0'?>\n")

	for {
		t, _ := decoder.Token()
		if t == nil {
			break
		}
		switch se := t.(type) {
			case xml.StartElement:
				inElement := se.Name.Local
				if inElement == "svg" {
					startOut(se, false)
					fmt.Fprintf(os.Stdout, "<filter id='g'><feGaussianBlur stdDeviation='%d'/></filter>", *deviation)
				} else if inElement == "g" {
					openG++
					if openG == 1 {
						firstGstartOut(se)
					} else {
						startOut(se, false)
					}
				} else if inElement == "polygon" || inElement == "ellipse" || inElement == "rect" || inElement == "path" {
					startOut(se, true)
				} else {
					startOut(se, false)
				}
			case xml.EndElement:
				inElement := se.Name.Local
				if inElement == "g" {
					openG--
					endOut(se)
				} else if inElement != "polygon" && inElement != "ellipse" && inElement != "rect" && inElement != "path" {
					endOut(se)
				}
			default:
		}
	}
    
}

func firstGstartOut(se xml.StartElement) {
	fmt.Fprintf(os.Stdout, "<%s filter='url(#g)'", se.Name.Local)
	
	for _, attr := range se.Attr {
		fmt.Fprintf(os.Stdout, " %s='%s'", attr.Name.Local, attr.Value)
	}
	fmt.Fprintf(os.Stdout, ">")
}

func endOut(ee xml.EndElement) {
	fmt.Fprintf(os.Stdout, "</%s>", ee.Name.Local)	
}

func startOut(se xml.StartElement, close bool) {
	fmt.Fprintf(os.Stdout, "<%s", se.Name.Local)
	for _, attr := range se.Attr {
		fmt.Fprintf(os.Stdout, " %s='%s'", attr.Name.Local, attr.Value)
	}
	if close {
		fmt.Fprintf(os.Stdout, "/")
	}
	fmt.Fprintf(os.Stdout, ">")
}

func header() {
    fmt.Fprintf(os.Stderr, "Bluring for primitive SVG images.\n")
    fmt.Fprintf(os.Stderr, "Copyright (c) 2017 Sascha Kohlmann.\n")
}

func usage(prgName string) {
    fmt.Fprintf(os.Stderr, "usage: %s [options] primitive.svg\n\n", prgName	)
    header()
    fmt.Fprintf(os.Stderr, "\nOptions:\n")
    fmt.Fprintf(os.Stderr, "  -h            : prints this help\n")
    fmt.Fprintf(os.Stderr, "  -d deviation  : optional gausian deviation value. Default: 12\n")
}
