# Blur for primitive

Simple command line tool to inject blur filter to Michael Fogleman [primitive](https://github.com/fogleman/primitive) SVG output.

# Build

Precondition: installed `go` 1.8.3

Clone the repository and type

<pre>
    go build blur4primitive.go
</pre>


# Run

Execute 
<pre>
    ./blur4primitive
</pre>

from command line to get the command line options.

Use `test.svg` for a first test run:

<pre>
    ./blur4primitive -d 9 test.svg
</pre>

The output is printed to `stdout`.
