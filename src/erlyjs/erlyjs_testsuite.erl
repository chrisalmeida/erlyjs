%%%-------------------------------------------------------------------
%%% File:      erlyjs_suite.erl
%%% @author    Roberto Saccon <rsaccon@gmail.com> [http://rsaccon.com]
%%% @copyright 2007 Roberto Saccon
%%% @doc       ErlyJS regression test suite
%%% @end
%%%
%%% The MIT License
%%%
%%% Copyright (c) 2007 Roberto Saccon
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in
%%% all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%%% THE SOFTWARE.
%%%
%%% @since 2007-12-14 by Roberto Saccon
%%%-------------------------------------------------------------------
-module(erlyjs_testsuite).
-author('rsaccon@gmail.com').

%% API
-export([run/0, test/1]).

%%====================================================================
%% API
%%====================================================================

%%--------------------------------------------------------------------
%% @spec () -> Ast::tuple()
%% @doc
%% @end 
%%--------------------------------------------------------------------
run() ->    
    case fold_tests("\.js$", false) of
        {N, []}->
            Msg = lists:concat(["All ", N, " regression tests passed"]),
            {ok, Msg};
        {_, Errs} -> 
            {error, Errs}
    end.
    
    
test(Name) ->
    case make:all([load]) of
        up_to_date ->
            case fold_tests(Name ++ ".js$", true) of
                {0, _} -> {error, "Test not found: " ++ Name ++ ".js"};
                {1, []} -> {ok, "Regression test passed"};
                {1, Errs} -> {error, Errs};
                {_, _} -> {error, "Testsuite requires different filename for each test"}
            end;
        _ ->
            {error, "ErlyJS library compilation failed"}
    end.
 
	
%%====================================================================
%% Internal functions
%%====================================================================

fold_tests(RegExp, Verbose) ->
    filelib:fold_files(test_doc_root(), RegExp, true, 
        fun
            (File, {AccCount, AccErrs}) ->
                case test(File, Verbose) of
                    ok -> 
                        {AccCount + 1, AccErrs};
                    {error, Reason} -> 
                        {AccCount + 1, [{File, Reason} | AccErrs]}
                end
        end, {0, []}).    

    
test(File, Verbose) ->   
	Module = filename:rootname(filename:basename(File)),
	case erlyjs_compiler:compile(File, Module, [{force_recompile, true}, {verbose, Verbose}]) of
	    ok ->
	        ProcessDict = get(),
	        M = list_to_atom(Module),
	        Expected = case M:js_test_result() of
	            Val when is_integer(Val) ->
	                float(Val);
	            Other ->
	                Other
	        end,
	        Args = M:js_test_args(),
	        M:jsinit(),
	        Result = case catch apply(M, js_test, Args) of
	            Expected -> 
	                ok;
	            Val1 when is_integer(Val1) ->
	                case float(Val1) of
        	            Expected ->
        	                ok;
        	            Other1 ->
        	                {error, "test failed: " ++ Module ++ " Result: " ++ Other1}
        	        end;
	            Other2 ->
	                {error, "test failed: " ++ Module ++ " Result: " ++ Other2}
	        end,
	        M:jsreset(),
	        case get() of
	            ProcessDict ->
	                Result;
	            _ ->
	                {error, "test failed: " ++ Module ++ " (dirty Process Dictionary)"}
	        end;	                
	    Err ->
	       Err 
	end.
	
	
test_doc_root() ->
    {file, Ebin} = code:is_loaded(?MODULE),
    filename:join([filename:dirname(filename:dirname(Ebin)), "src", "tests"]).