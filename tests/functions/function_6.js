// Mandatory. Return here a description of the test case.
function test_description() {
    return "lambda with a free variable (shadowing)";
}

// Mandatory. Return here an array of arguments the testsuite will use
// to invoke the test() function. For no arguments return an empty array.
function test_args() {
    return [];
}

// Mandatory. Return here the expected test result.
function test_ok() {
    return 4;
}

// Optional. Provide here any global code.


// Mandatory. The actual test.
// Testsuite invokes this function with the arguments from test_args()
// and compares the return value with the expected result from test_ok().
function test() {
  var a = 40, b = 2;
  function fun(a) {
    return a + b;
  }
  return fun(2);
}
