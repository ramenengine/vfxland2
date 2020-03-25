\ cleaner float wordlist

wordlist constant fclean
fclean +order definitions

synonym + f+
synonym - f-
synonym * f*
synonym / f/
synonym min fmin
synonym max fmax
synonym mod fmod
synonym sin fsin
synonym cos fcos
synonym asin fasin
synonym acos facos
synonym tan ftan
synonym atan2 fatan2
synonym .r   f.r
synonym .   f.
synonym sqrt fsqrt
synonym abs fabs
synonym negate fnegate
synonym cosec fcosec 
synonym sec fsec
synonym cotan fcotan
synonym sinh fsinh
synonym cosh fcosh
synonym tanh ftanh
synonym asinh fasinh
synonym acosh facosh
synonym atanh fatanh
synonym log flog
synonym exp fexp
synonym ** f**

synonym dup  fdup
synonym drop fdrop
synonym over fover
synonym swap fswap
synonym 2dup  f2dup
synonym 2drop f2drop
synonym 2over f2over
synonym 2swap f2swap
synonym nip   fnip
synonym 4dup  f4dup
synonym rot   frot

: f[ fclean +order ;
: ]f fclean -order ;


fclean -order only forth definitions