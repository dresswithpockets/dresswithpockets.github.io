---
layout: post
title:  "Scoring competition participants on a curve (content warning: MATH 😱)"
date:   2025-10-09 12:00:00 -0700
tags:   math
published: false
---

I've been working on a scoring system that assigns points to participants in a competition based on their final placement in the event. The goal is to stack participants over a number of events based on their performance relative to other participants.

I want the system to be defined as a continuous increasing function such that each placement gains at least 1 point over the previous placement. So, 2nd-to-last place should gain at least 1 point over last place. Ideally, the system also rewards 1st place more than 2nd, 2nd more than 3rd, 3rd more than 4th, and so on until last place. The scoring function should be bounded between a minimum score and maximum score, and I should be able to vary the steepness of the curve.

## That sounds a lot like...

The bezier curve!

$$
\Large
B(a,b,r,t) = (1-t)^{2}a + 2(1 - t)tr + t^{2}b
$$

The quadratic bezier is a second-order interpolant. Its basically a fancy parabola, where the intermediate control value \(r\) varies the slope of the curve over \(t\). We can vary the inputs of B in order to shape the curve.

<video src="/assets/videos/scoring-system/simple.720p30.hevc.mp4" data-canonical-src="/assets/videos/scoring-system/simple.720p30.hevc.mp4" controls="controls" muted="muted" class="d-block rounded-bottom-2 border-top width-fit center-video" crossorigin="anonymous"></video>

## The score function

We need to be able to set:

$$
\begin{align*}
\text{the number of participants: } & N_0, \Set { N_0 \in \N | 2 \le N_0 } \\
\text{the lower score bound: } & S_0, \Set { S_0 \in \N | 1 \le S_n } \\
\text{the upper score bound: } & S_n, \Set { S_n \in \N | S_0 < S_n } \\
\text{the control coefficient: } & r_c, \Set { r_c \in \R | 0 \le r_c \le 1 } \\
\end{align*}
$$

We can calculate the intermediate control \(r\) as \(S_r\):

$$
\large
\begin{cases}
S_m & = \LARGE{\frac{S_0 + S_n}{2} } \\
S_r & = (1 - r_c)S_m + r_cS_0 \\
\end{cases}
$$

And define the scoring functions:

$$
\large
\begin{cases}
T(p) & = \bigg(1 - \frac{p - 1}{N_0 - 1}\bigg) & \Set{ p \in \N | 1 \leq p \leq N_0 } \\
S(p) & = B(S_0,\ S_n,\ S_r,\ T(p)) & \Set{ p \in \N | 1 \leq p \leq N_0 }
\end{cases}
$$

The scoring function so far is pretty simple. We can plot it and vary the inputs to get a curve with increasing steps between each place as \(p\) approaches 1.

<video src="/assets/videos/scoring-system/score1.720p30.hevc.mp4" data-canonical-src="/assets/videos/scoring-system/score1.720p30.hevc.mp4" controls="controls" muted="muted" class="d-block rounded-bottom-2 border-top width-fit center-video" crossorigin="anonymous"></video>

## Constraining the step size

Depending on the values of our inputs, this function can provide a score for every placement. Lets define the differential score of two places as \(\Delta S(p)\):

$$
\Large
\Delta S(p) = S(p) - S(p + 1) \text{ for all } \Set{ p \in \N | 1 \le p < N_0 }
$$

For example: \(\Delta S(1)\) gives us the 1st and 2nd place differential score, and \(\Delta S(N_0-1)\) gives us the differential score for second-to-last and last place. Given any parameterization of the inputs, we need to ensure that for all values of \(p\) in \(\mathbb N\), we must ensure the following **Differential Constraint** is always true:

$$
\Large
\Set{ p \in \N | 1 \le p \le N_0 - 1 \large{\text{ and }} \Large \Delta S(p) \ge 1 }
$$

Variations in \(\large r_c\) can cause the Differential Constraint to fail given a small enough \(N_0\), or small enough \(S_n - S_0\). So, we should find a set \(\large R_c\) of all \(\large r_c\) for which the Differential Constraint is true:

$$
\Large
R_c = \Set{ r_c \in \R | 0 \le r_c \le 1 \large{\text{ and }} \Large \Delta S(p) \ge 1 }
$$

Expanding \(\Delta S(p)\) gives:

$$
\large
\begin{equation*}
\begin{split}

\Delta S(p) &= S(p) - S(p + 1) \\
&= B(S_0,\ S_n,\ S_r,\ T(p)) - B(S_0,\ S_n,\ S_r,\ T(p + 1)) \\
&= \bigg((1 - T(p))^{2}S_0 + 2(1 - T(p))T(p)S_r + T(p)^{2}S_n\bigg) - {}\\
&\ \ \ \ \ \bigg((1 - T(p + 1))^{2}S_0 + 2(1 - T(p + 1))T(p + 1)S_r + T(p + 1)^{2}S_n\bigg) \\

&= \bigg((1 - T(p))^{2}S_0 + 2(1 - T(p))T(p)S_r + (T(p))^{2}S_n\bigg) - {}\\
&\ \ \ \ \ \bigg((1 - T(p + 1))^{2}S_0 + 2(1 - T(p + 1))T(p + 1)S_r + (T(p + 1))^{2}S_n\bigg) \\

&= -2S_rT(p + 1) + 2S_rT(p) + 2S_rT(p + 1)^2 - 2S_rT(p)^2 + {}\\
&\ \ \ \ \ \  2S_0T(p + 1) - 2S_0T(p) - S_0T(p + 1)^2 + S_0T(p)^2 - {}\\
&\ \ \ \ \ \  S_nT(p + 1)^2 + S_nT(p)^2\\

\end{split}
\end{equation*}
$$

We only care about the smallest value of \(\Delta S(p)\). We know that as \(p\) approaches \(0\), \(\Delta S(p)\) will increase, therefore the smallest value will always be \(\Delta S(N_0 - 1)\), given the constraints on \(p\) defined by \(\Delta S(p)\). We can simplify for \(\Delta S(N_0 - 1)\) as:

$$
\large
\begin{equation*}
\begin{split}

T(N_0) &= 1 - \frac{N_0 - 1}{N_0 - 1}\\
&= 1 - 1\\
&= 0\\

T(N_0 - 1) &= 1 - \frac{N_0 - 1 - 1}{N_0 - 1}\\
&= 1 - \frac{N_0 - 2}{N_0 - 1}\\
&= \frac{N_0 - 1}{N_0 - 1} - \frac{N_0 - 2}{N_0 - 1}\\
&= \frac{\cancel{N_0 - N_0} + 2 - 1}{N_0 - 1}\\
&= \frac{1}{N_0 - 1}\\

\Delta S(N_0 - 1) &= -2S_rT(N_0) + 2S_rT(N_0 - 1) + 2S_rT(N_0)^2 - 2S_rT(N_0 - 1)^2 + {}\\
&\ \ \ \ \ \  2S_0T(N_0) - 2S_0T(N_0 - 1) - S_0T(N_0)^2 + S_0T(N_0 - 1)^2 - {}\\
&\ \ \ \ \ \  S_nT(N_0)^2 + S_nT(N_0 - 1)^2\\

&= \cancel{-2S_r0} + 2S_r\frac{1}{N_0 - 1} + \cancel{2S_rT0^2} - 2S_r\frac{1}{N_0 - 1}^2 + {}\\
&\ \ \ \ \ \  \cancel{2S_00} - 2S_0\frac{1}{N_0 - 1} - \cancel{S_00^2} + S_0\frac{1}{N_0 - 1}^2 - {}\\
&\ \ \ \ \ \  \cancel{S_n0^2} + S_n\frac{1}{N_0 - 1}^2\\

&= 2S_r\frac{1}{N_0-1} + -2S_0\frac{1}{N_0-1} + -2S_r\frac{1}{N_0-1}^{2} + S_0\frac{1}{N_0-1}^{2} + S_n\frac{1}{N_0-1}^{2}\\

&= \frac{2S_r - 2S_0}{N_0-1} + \frac{-2S_r + S_0 + S_n}{(N_0-1)^2}\\

\end{split}
\end{equation*}
$$

\(\large S_r\) needs to be expanded before we can simplify futher:

$$
\large
\begin{equation*}
\begin{split}

S_r &= (1 - r_c)(\frac{S_0 + S_n}{2}) + r_cS_0\\
&= \frac{(1 - r_c)(S_0 + S_n)}{2} + r_cS_0\\
&= \frac{S_0 + S_n - S_0r_c - S_nr_c}{2} + r_cS_0\\
&= \frac{S_0 + S_n - S_nr_c + S_0r_c}{2}\\
2S_r &= S_0 + S_n - S_nr_c + S_0r_c\\

\end{split}
\end{equation*}
$$

Substituting all \(2S_r\) in our simplified \(\Delta S(N_0 -1)\), we are able to simplify even further:

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 -1) &= \frac{S_0 + S_n - S_nr_c + S_0r_c - 2S_0}{N_0-1} + \frac{-S_0 - S_n + S_nr_c - S_0r_c + S_0 + S_n}{(N_0-1)^2}\\

&= \frac{S_n - S_nr_c + S_0r_c - S_0}{N_0-1} + \frac{S_nr_c - S_0r_c}{(N_0-1)^2}\\

&= \frac{(S_n - S_nr_c + S_0r_c - S_0)(N_0-1)}{(N_0-1)^2} + \frac{S_nr_c - S_0r_c}{(N_0-1)^2}\\

&= \frac{S_nN_0 - S_nr_cN_0 + S_0r_cN_0 - S_0N_0 - S_n + S_nr_c - S_0r_c + S_0 + S_nr_c - S_0r_c}{(N_0-1)^2}\\

&= \frac{S_nN_0 - S_nr_cN_0 + S_0r_cN_0 - S_0N_0 - S_n + 2S_nr_c - 2S_0r_c + S_0}{(N_0-1)^2}\\

\end{split}
\end{equation*}
$$

Now that we have \(\Delta S(N_0 -1)\) in terms of \(\large r_c\), we can rephrase as an inequality and solve for \(\large r_c\):

$$
\large
\begin{equation*}
\begin{split}

1 &\ge \frac{- S_nN_0r_c + S_0N_0r_c + 2S_nr_c - 2S_0r_c + S_nN_0 - S_0N_0 - S_n + S_0}{(N_0-1)^2}\\

1 &\ge \frac{- S_nN_0r_c + S_0N_0r_c + 2S_nr_c - 2S_0r_c + S_nN_0 - S_0N_0 - S_n + S_0}{(N_0-1)^2}\\

(N_0 - 1)^2 &\ge - S_nN_0r_c + S_0N_0r_c + 2S_nr_c -2S_0r_c + S_nN_0 - S_0N_0 - S_n + S_0\\
(N_0 - 1)^2 - S_nN_0 + S_0N_0 + S_n - S_0 &\ge r_c(-S_nN_0 + S_0N_0 + 2S_n - 2S_0)\\
r_c(-S_nN_0 + S_0N_0 + 2S_n - 2S_0) &\le (N_0 - 1)^2 - S_nN_0 + S_0N_0 + S_n - S_0\\
r_c &\le \frac{(N_0 - 1)^2 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0}\\
r_c &\le \frac{N_0^2 - 2N_0 + 1 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0}\\

\end{split}
\end{equation*}
$$

We can plug in some sample inputs to spot-check that our inequality makes sense:

$$
\large
\begin{equation*}
\begin{split}

N_0 &= 500\\
S_0 &= 1000\\
S_n &= 100,000\\

r_c &\le \frac{500^2 - 2(500) + 1 - 100000(500) + 1000(500) + 100000 - 1000}{-100000(500) + (1000)(500) + 2(100000) - 2(1000)}\\
r_c &\le \frac{−49151999}{−49302000}\\
r_c &\le \frac{49151999}{49302000}\\
r_c &\lessapprox 0.9969575067948562\\

\end{split}
\end{equation*}
$$

Evaluating \(\Delta S(N_0 - 1)\) with \(r_c = \frac{49151999}{49302000}\) should then yield \(1\):

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 - 1) &= \frac{S_nN_0 - S_nr_cN_0 + S_0r_cN_0 - S_0N_0 - S_n + 2S_nr_c - 2S_0r_c + S_0}{(N_0 - 1)^2}\\
&= \frac{100000(500) - 100000r_c(500) + 1000r_c(500) - 1000(500) - 100000 + 2(100000)r_c - 2(1000)r_c + 1000}{(500 - 1)^2}\\
&= \frac{50000000 - 50000000r_c + 500000r_c - 500000 - 100000 + 200000r_c - 2000r_c + 1000}{249001}\\
&= \frac{50000000 - 500000 - 100000 + 1000 + r_c(-50000000 + 500000 + 200000 - 2000)}{249001}\\
&= \frac{49401000 − 49302000r_c}{249001}\\
&= \frac{49401000 − 49302000\frac{49151999}{49302000} }{249001}\\
&= \frac{249001}{249001}\\
&= 1\\

\end{split}
\end{equation*}
$$

Excellent (:

Finally, we can define \(\large R_c\) in terms of our inequality on \(\large r_c\):

$$
\Large
R_c = \Set{ r_c \in \R | 0 \le r_c \le \frac{N_0^2 - 2N_0 + 1 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0}}
$$

This set implies \(\Delta S(p) \ge 1 \) because \(r_c \le \large \frac{N_0^2 - 2N_0 + 1 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0}\) was solved from the inequality \(\Delta S(p) \ge 1 \).

## A better curve

The curve created by \(S(p)\) does fulfill my original requirements, but I feel it should reward better placements more dramatically. I want to be able to control how dramaticaly the slope rises as \(p\) approaches \(1\) from \(N_0\). I'll try by createing an n-th order variant of our score function.

Lets define a new input:

$$
\Large
\text{the control exponent: } r_e, \Set{ r_e \in \R | 1 \le r_e }
$$

And redefine the score functions to include \(r_e\):

$$
\large
\begin{cases}
T(p) &= \bigg(1 - \frac{p - 1}{N_0 - 1}\bigg) & \Set{ p \in \N | 1 \leq p \leq N_0 } \\
S(p) &= B(S_0,\ S_n,\ S_r,\ T(p)^{r_e}) & \Set{ p \in \N | 1 \leq p \leq N_0 }\\
\end{cases}
$$

Just as with our 2nd-order \(S(p)\), the Differential Constraint should remain true:

$$
\large
\begin{cases}
\Delta S(p) = S(p) - S(p + 1) &\text{ for all } \Set{ p \in \N | 1 \le p < N_0 }\\
\Delta S(p) \ge 1 &\text{ for all } \Set{ p \in \N | 1 \le p \le N_0 - 1 }\\
\end{cases}
$$

Unfourtunately, given the higher order \(T(p)^{r_e}\), small variations in \(\large{r_e}\) can cause the Differential Constraint to fail given a small enough \(N_0\), large enough \(r_c\), or small enough \(S_n - S_0\). So, we should find a set \(\large E\) of all \(\large r_e\) for which the Differential Constraint is true:

$$
\Large
% \lim\limits_{p \longrightarrow N_0}{\Delta S(p) \ge 1}

E = \Set { r_e \in \R | 1 \le r_e \large{\text{ and }} \Large \Delta S(p) \ge 1 }
$$

Just as with our 2nd order \(S(p)\), we're going to need to solve \(\Delta S(p)\) in terms of \(\large r_e\). We can reuse the original expansion of \(\Delta S(p)\), because the \(T(p)\) substitutions are unaltered in the simplified form of \(\Delta S(p)\):

$$
\large
\begin{equation*}
\begin{split}

\Delta S(p) &= S(p) - S(p + 1) \\
&= B(S_0,\ S_n,\ S_r,\ T(p)^{r_e}) - B(S_0,\ S_n,\ S_r,\ T(p + 1)^{r_e}) \\
&= -2S_rT(p + 1)^{r_e} + 2S_rT(p)^{r_e} + 2S_rT(p + 1)^{2r_e} - 2S_rT(p)^{2r_e} + {}\\
&\ \ \ \ \ \  2S_0T(p + 1)^{r_e} - 2S_0T(p)^{r_e} - S_0T(p + 1)^{2r_e} + S_0T(p)^{2r_e} - {}\\
&\ \ \ \ \ \  S_nT(p + 1)^{2r_e} + S_nT(p)^{2r_e}\\
\end{split}
\end{equation*}
$$

Just as with our 2nd order variant, we only care about the smallest value of \(\Delta S(p)\), which will be \(\Delta S(N_0 - 1)\) as we showed earlier. We can reuse a simplification that preserves our \(T\) invocations, adding in our exponent:

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 - 1) &= 2S_r\frac{1}{N_0-1}^{r_e} + -2S_0\frac{1}{N_0-1}^{r_e} + -2S_r\frac{1}{N_0-1}^{2r_e} + S_0\frac{1}{N_0-1}^{2r_e} + S_n\frac{1}{N_0-1}^{2r_e}

\end{split}
\end{equation*}
$$

Lets substitute out \(\Large \frac{1}{N_0-1}^{r_e}\) with a term \(N\):

$$
\large
\begin{equation*}
\begin{split}

\Delta S(N_0 - 1) &= 2S_rN - 2S_rN^2 - 2S_0N + S_0N^2 + S_nN^2\\
&= S_0N^2 + S_nN^2 - S_rN^2 - 2S_0N + 2S_rN\\
&= (S_0 + S_n - 2S_r)N^2 + (-2S_0+2S_r)N\\

\end{split}
\end{equation*}
$$

Now we can rephrase the quadratic interms of \(N\):

$$

\large
\begin{equation*}
\begin{split}

a &= S_0 + S_n - 2S_r \\
b &= -2S_0 + 2S_r \\
\Delta S(N_0 - 1) &= aN^2 +bN\\

\end{split}
\end{equation*}
$$

<!-- 
\(1 - r_c\) has the domain \([1, 0]\), \(S_n\) has the domain \([S_0 + 1, \infty)\).

\(S_n(1 - r_c)\) has a the domain \([1, 0] \cdot [S_0 + 1, \infty) = [S_0 + 1,\) $\Set{S_n \in \N | S_n > S_0 > 1 } \cdot (1 - \Set{ r_c \in \R | 0 \le r_c \le 1 })$

Since \(S_n > S_0\), we can infer that \(a > 0\) and \(b > 0\).

0 = ar - a + b - rb
a - ar = b - rb -->

Once we solve for \(N\), we can then rearrange to solve for all values of \(r_e\) that fulfill our inequality, in terms of \(r_c, S_0, S_n, N_0\):

$$
\large
1 \le aN^2 +bN\\
$$

Before solving the quadratic, lets consider the roots.  We can simplify \(a\) and \(b\) into the the simplest terms:

$$
\large
\begin{equation*}
\begin{split}

a &= S_0 + S_n - 2S_r \\
  &= S_0 + S_n - 2((1-r_c)S_m + r_cS_0)\\
  &= S_0 + S_n - 2((1 - r_c)\frac{S_0 + S_n}{2} + r_cS_0)\\
  &= S_0 + S_n - 2(\frac{S_0 + S_n - r_cS_0 - r_cS_n}{2} + r_cS_0)\\
  &= S_0 + S_n - S_0 - S_n + r_cS_0 + r_cS_n - 2r_cS_0\\
  &= r_cS_0 + r_cS_n - 2r_cS_0\\
  &= r_cS_n - r_cS_0\\
  &= r_c(S_n - S_0)\\\\

b &= -2S_0 + 2S_r \\
  &= -2S_0 + 2((1-r_c)S_m + r_cS_0) \\
  &= -2S_0 + S_0 + S_n - r_cS_0 - r_cS_n + 2r_cS_0\\
  &= -S_0 + S_n - r_cS_n + r_cS_0\\
  &= r_c(S_0 - S_n) - S_0 + S_n\\
  &= (S_0 - S_n)(r_c - 1)\\

\end{split}
\end{equation*}
$$

We can then clearly see that when \(\large r_c = 0, \ a = 0S_n - 0S_0 = 0\), and that when \(\large r_c = 1, \ b = S_0(1 - 1) + S_n(1-1) = 0\). Therefore, there are equations to consider:

$$
\large
\begin{align*}
1 &\le aN^2 + bN &\text{ when } &0 < r_c < 1 \\
1 &\le bN &\text{ when } &r_c = 0  \\
1 &\le aN^2 &\text{ when } &r_c = 1 \\
\end{align*}
$$

Then we must solve for \(N\) in all three cases:

$$
\large
\begin{align}
\frac{-b + \sqrt{b^2 + 4a}}{2a} \le N &\le \frac{-b - \sqrt{b^2 + 4a}}{2a} &\text{ when } &0 < r_c < 1 \\
% \frac{1}{2}\bigg(\frac{\sqrt{b^2 - 4ac} - b}) \le N &\le &0 < r_c < 1\\
\frac{1}{b} &\le N &\text{ when } &r_c = 0 \\
\sqrt{\frac{1}{a}} &\le N &\text{ when } &r_c = 1 \\
\end{align}

% \begin{equation*}
% \begin{split}

% \frac{-b + \sqrt{b^2 + 4a}}{2a} \le N &\le \frac{-b - \sqrt{b^2 + 4a}}{2a}\\

% \end{split}
% \end{equation*}
$$

Lets start by substituting & solving the two simple cases:

$$
\large
\begin{align*}
\frac{1}{S_n - S_0} &\le N &\text{ when } &r_c = 0 \\
\sqrt{\frac{1}{S_n - S_0}} &\le N &\text{ when } &r_c = 1 \\
\end{align*}
$$

### solving \(r_e\) when \(r_c = 0\)

Substituting N:

$$
\large
\begin{align*}
N &\ge \frac{1}{S_n - S_0}\\
\bigg(\frac{1}{N_0 - 1}\bigg)^{r_e} &\ge \frac{1}{S_n - S_0}\\
\end{align*}
$$

Solving for \(r_e\) with change of base:

$$
\large
\begin{align*}
r_e \ln \frac{1}{N_0 - 1} &\ge \ln \frac{1}{S_n - S_0}\\
r_e &\le \ln \frac{1}{S_n - S_0} \Bigg/ \ln \frac{1}{N_0 - 1}\\
\end{align*}
$$

Solving for an example value to spot check with:

$$
\large

\begin{align*}
N_0 &= 200\\
S_0 &= 1000\\
S_n &= 100000\\

r_e &\le \ln \frac{1}{100000 - 1000} \Bigg/ \ln \frac{1}{200 - 1}\\
r_e &\le \ln \frac{1}{99000} \Bigg/ \ln \frac{1}{199}\\
r_e &\lessapprox 2.173098944800602
\end{align*}
$$

Plugging the value back in to \(\large \Delta S(p)\), which should get a value close to \(1\):

$$
\large

\begin{align*}

S_m &= \frac{1000 + 100000}{2} = 50500\\
S_r &= (1 - 0)50500 + 0(1000) = 50500\\
r_e &\approx 2.173098944800602\\

T(199) &\approx \bigg(\frac{1}{199 - 1}\bigg)^{2.173098944800602} \approx 0.0000102121996910658 \\
T(200) &\approx \bigg(\frac{1}{200 - 1}\bigg)^{2.173098944800602} \approx 0.00001010101010101007 \\

S(199) &= B(1000, 100000, 50500, 0.0000102121996910658) \approx 1001\\
S(200) &= B(1000, 100000, 50500, 0.00001010101010101007) \approx 1000\\

\Delta S(199) &\approx 1001 - 1000 \approx 1
\end{align*}
$$

Yippee!!!

### solving \(r_e\) when \(r_c = 1\)

I'll follow the same process. Subsituting for N and solving for \(r_e\) with change of base:

$$
\large
\begin{align*}
N &\ge \sqrt{\frac{1}{S_n - S_0}}\\
\bigg(\frac{1}{N_0 - 1}\bigg)^{r_e} &\ge \sqrt{\frac{1}{S_n - S_0}}\\
r_e \ln \frac{1}{N_0 - 1} &\ge \ln \sqrt{\frac{1}{S_n - S_0}}\\
r_e &\le \ln \sqrt{\frac{1}{S_n - S_0}} \Bigg/ \ln \frac{1}{N_0 - 1}\\
\end{align*}
$$

Solving for an example value to spot check with:

$$
\large

\begin{align*}
N_0 &= 200\\
S_0 &= 1000\\
S_n &= 100000\\

r_e &\le \ln \sqrt{\frac{1}{100000 - 1000}} \Bigg/ \ln \frac{1}{200 - 1}\\
r_e &\le \ln \sqrt{\frac{1}{99000}} \Bigg/ \ln \frac{1}{199}\\
r_e &\lessapprox 1.086549472400301
\end{align*}
$$

Plugging the value back in to \(\large \Delta S(p)\), which should get a value close to \(1\):

$$
\large

\begin{align*}

S_m &= \frac{1000 + 100000}{2} = 50500\\
S_r &= (1 - 0)50500 + 0(1000) = 50500\\
r_e &\approx 1.086549472400301\\

T(199) &\approx \bigg(\frac{1}{199 - 1}\bigg)^{1.086549472400301} \approx 0.0000102121996910658 \\
T(200) &\approx \bigg(\frac{1}{200 - 1}\bigg)^{1.086549472400301} \approx 0.00001010101010101007 \\

S(199) &= B(1000, 100000, 50500, 0.0000102121996910658) \approx 1001\\
S(200) &= B(1000, 100000, 50500, 0.00001010101010101007) \approx 1000\\

\Delta S(199) &\approx 1001 - 1000 \approx 1
\end{align*}
$$

Yayy!!!

### solving \(r_e\) when \(0 < r_c < 1\)

Now I can worry about the tougher one, substituting and simplifying both sides of the quadratic while making sure to retain the signed square root's side & inequality:

$$
\large
\begin{align*}

& \frac{-(S_0 - S_n)(r_c - 1) \pm \sqrt{[(S_0 - S_n)(r_c - 1)]^2 + 4r_c(S_n - S_0)}}{2r_c(S_n - S_0)}\\
& \frac{\cancel{(S_n - S_0)}(r_c - 1)}{2r_c\cancel{(S_n - S_0)}} \pm \sqrt{\frac{(S_0 - S_n)^2(r_c - 1)^2 + 4r_c(S_n - S_0)}{4r_c^2(S_n - S_0)^2}}\\
& \frac{r_c - 1}{2r_c} \pm \sqrt{\frac{-\cancel{(S_n - S_0)}(S_0 - S_n)(r_c - 1)^2 + 4r_c\cancel{(S_n - S_0)}}{4r_c^2(S_n - S_0)^{\cancel{2}}}}\\
& \frac{r_c - 1}{2r_c} \pm \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}}\\

\end{align*}
$$

Fitting the simplified form back into the inequality with the appropriate signs & direction preserved, so that I can solve for \(r_e\)

$$
\large
\begin{align*}

\frac{r_c - 1}{2r_c} + \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}} \le N \le \frac{r_c - 1}{2r_c} - \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}}\\

\end{align*}
$$

We can perform a change of base to solve for \(r_e\). Note the direction of inequality has changed due to the division of the decreasing function \(ln(\frac{1}{N_0 - 1})\), which has the limit \(\lim\limits_{N_0\longrightarrow\infty} ln(\frac{1}{N_0 - 1}) = -\infty \text{ for all } \lbrace N_0 \in \mathbb{R} \mid N_0 > 1\rbrace\).

$$
\large
\begin{align*}

\frac{\ln(\frac{r_c - 1}{2r_c} + \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}})}{\ln(\frac{1}{N_0 - 1})} \ge r_e &\ge \frac{\ln(\frac{r_c - 1}{2r_c} - \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}})}{\ln(\frac{1}{N_0 - 1})} \\

\end{align*}
$$

I may have some cases where the solution to parts of this expression are imaginary:

$$

\sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}} \in \Complex \text{ when } \frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)} < 0 \\

\text{ or }\\

\ln(\frac{r_c - 1}{2r_c} \pm \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}}) \in \Complex \text{ when } \frac{r_c - 1}{2r_c} \pm \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}} < 0

$$

It turns out that \(\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)} < 0\) is never true, because it implies \((S_n - S_0)(r_c - 1)^2 + 4r_c < 0\). \(r_c - 1\) can be negative when \(r_c < 1\) - so always for \(0 < r_c < 1) - but that expression is squared, so the result will always be positive. Therefore, the inner square root will never be imaginary.

However, the logarithm can be imaginary. The root scales by \(S_n\) and \(S_0\), and will always be greater than \(\frac{r_c - 1}{2r_c}\). Taking a look at the inequality:

$$
\large
\begin{align*}

\frac{r_c - 1}{2r_c} \pm \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}} &< 0\\
\pm \frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)} &< \frac{r_c - 1}{2r_c}^2\\
\pm \frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)} &< \frac{(r_c - 1)^2}{4r_c^2}\\
\pm \frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)} &< \frac{(S_n - S_0)(r_c - 1)^2}{4r_c^2(S_n - S_0)}\\

\end{align*}
$$

Since the sides are equivalent other than the \(+ 4r_c\) in the numerator on the left side, which is always positive, this inequality has no real solutions with the positive root. In contrast this inequality is always true when the root is negative. Therefore, \(\ln(\frac{r_c - 1}{2r_c} - \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}})\) is always imaginary, and \(\ln(\frac{r_c - 1}{2r_c} + \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}})\) is never imaginary. I'll define a set \(E_r\):

$$
\large
\begin{align*}

E_r &= \Set { r_c \in \R | 0 < r_c < 1 (\exists r_e \in \R)\Bigg[1 \le r_e \le \ln\bigg(\frac{r_c - 1}{2r_c} + \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}}\bigg) \Bigg/ \ln(\frac{1}{N_0 - 1}) \Bigg]}\\

&\because \Delta S(p) \ge 1 \impliedby \ln\bigg(\frac{r_c - 1}{2r_c} + \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}}\bigg) \Bigg/ \ln(\frac{1}{N_0 - 1})\\

\end{align*}
$$

Now I can verify by plugging in some values:

$$
\large
\begin{equation*}
\begin{split}

r_c &= 0.5\\
N_0 &= 500\\
S_0 &= 1000\\
S_n &= 100,000\\

re &\le \frac{\ln(\frac{0.5 - 1}{2(0.5)} + \sqrt{\frac{(100000 - 1000)(0.5 - 1)^2 + 4(0.5)}{4(0.5)^2(100000 - 1000)}})}{\ln(\frac{1}{500 - 1})}\\
re &\le \frac{\ln(-\frac{1}{2} + \sqrt{\frac{24752}{99000}})}{\ln(\frac{1}{499})}\\
re &\lessapprox 1.73996998737\\

\end{split}
\end{equation*}
$$

Plugging the value back in to \(\large \Delta S(p)\), which should get a value close to \(1\):

$$
\large

\begin{align*}

S_m &= \frac{1000 + 100000}{2} = 50500\\
S_r &= (1 - 0.5)50500 + 0.5(1000) = 25750\\
r_e &\approx 1.73996998737\\

T(499) &\approx \bigg(\frac{1}{499 - 1}\bigg)^{1.73996998737} \approx 0.00002027224725513445 \\
T(500) &\approx \bigg(\frac{1}{500 - 1}\bigg)^{1.73996998737} \approx 0.00002020161209699543 \\

S(499) &= B(1000, 100000, 25750, 0.00002027224725513445) \approx 1001\\
S(500) &= B(1000, 100000, 25750, 0.00002020161209699543) \approx 1000\\

\Delta S(499) &\approx 1001 - 1000 \approx 1
\end{align*}
$$

Yippee!!! Given our constraints on the parameters, lets define sets that describe the valid domain of \(\large r_e\) such that the Differential Constraint is fullfilled:

$$
\large
\begin{equation*}
\begin{split}

R_c &= \Set{r_c \in \R | 0 < r_c \le 1}\\
R_c &= \Set{r_c \in \R | 0 \le r_c \le \frac{N_0^2 - 2N_0 + 1 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0}}\\
E_0 &= \Set{(r_c, r_e) \in R_c \times \N | r_c = 0 \land 1 \le r_e \le \ln \frac{1}{S_n - S_0} \Bigg/ \ln \frac{1}{N_0 - 1}}\\
E_1 &= \Set{(r_c, r_e) \in R_c \times \N | r_c = 1 \land 1 \le r_e \le \ln \sqrt{\frac{1}{S_n - S_0}} \Bigg/ \ln \frac{1}{N_0 - 1}}\\
E_r &= \Set{(r_c, r_e) \in R_c \times \N | 0 < r_c < 1 \land 1 \le r_e \le \ln\bigg(\frac{r_c - 1}{2r_c} + \sqrt{\frac{(S_n - S_0)(r_c - 1)^2 + 4r_c}{4r_c^2(S_n - S_0)}}\bigg) \Bigg/ \ln\frac{1}{N_0 - 1}}\\
\end{split}
\end{equation*}
$$

Then the set of all valid \(\large r_e\) can be redefined as:

$$
\large 
E = E_0 \land E_1 \land E_r
$$

## Sum of the parts

Earlier we created a constraint for \(\large r_c\) for a 2nd-order \(S(p)\). That constraint is still valid for nth-order \(S(p)\) when \(r_e = 1\). Even with our nth-order function, we still need to ensure we meet the constraint on \(\large r_c\), otherwise \(\Delta S(N_0 - 1)\) may become smaller than 1. So, we can redefine the set \(R_c\) such that \(\large r_c\) is always correctly constrained first:

$$
\large
R_c = \Set{r_c \in \R | 0 < r_c \le \frac{N_0^2 - 2N_0 + 1 - S_nN_0 + S_0N_0 + S_n - S_0}{-S_nN_0 + S_0N_0 + 2S_n - 2S_0} }
$$

So long as \(\large r_e\) is in \(E\), that implies that \(\large r_c\) is in \(R_c\)! We've fully constrainted both \(\large r_c\) and \(\large r_e\). The scoring function \(S(p)\) can be varied for any valid inputs, and it will output a useful score that represents relative performance.
