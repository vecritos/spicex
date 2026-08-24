# Taylor Series

our task is to create an infinate polynomial power series that emulates some function $f(x)$ near $x=0$ for this to happen, our polynomial $P(x) \land f(x)$ should have the same value at $x=0$ the same first derivative, second derivatives,.. @$x=0$

$\implies$

$P(x) = f(0) + f'(0)x + \frac{f"(0)}{2!}x^2 + \frac{f"'(0)}{3!}x^3 + ..$

this is known as the MaClarin Series for $f(x)$ or the Taylor Series centered at $x=0$

## LaGrange Error Bounds

For the nth order Taylor polynomial $\lvert f(c)-P_n(c) \rvert \le MAX_{a \le x \le c}\lvert f^{n+1}(x)\rvert\frac{(c-a)^{n+1}}{(n+1)!}$ when centered at $x=a$ commonly $a=0$