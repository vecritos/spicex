# Directional Derivatives

if $f$ is differentiable function of $x \land y$ then the directional derivative of $f$ in the direction of the unit vector $u = cos(\theta)i + sin(\theta)j$ is $D_u f(x,y) = f_x(x,y)cos\theta + f_y(x,y)sin\theta$

## Gradient of a Function of Two Variables

let $z=f(x,y)$ be a function of $x \land y$ such that $f_x \land f_y$ exist then the gradient of $f$ denoted $\nabla f(x,y)$ is the vector $\nabla f(x,y) = f_x(x,y)i+f_y(x,y)j$

## Alternate for of the Directional Derivative

$D_u f(x,y) = \nabla f(x,y) * \vec{u}$

## Properties of the Gradient

1) if $\nabla f(x,y) = 0 \implies D_u f(x,y) = 0 \forall \vec{u}$
2) direction of the maximum increase of $f$ is given by $\nabla f(x,y)$ the maximum value of $D_u f(x,y)$ is $\lvert\lvert\nabla f(x,y)\rvert\rvert$ the maximum value of $D_u f(x,y)$
3) The direction of minimum increase of f is given by $-\nabla f(x,y)$ the minimum value of $D_u f(x,y)$ is $-\lvert\lvert\nabla f(x,y)\rvert\rvert$

## Gradient is Normal to Level Curves

if $f$ is differentiable of $(x_0, y_0)$ and $\nabla f(x_0, y_0) \ne 0$ then $\nabla f(x_0,y_0)$ is normal to the level curve through $(x_0,y_0)$