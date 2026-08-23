# binary

> this outline shows the breakdown of an additional terminal character at each letter designation
> if you notice the terminal nodes and some of the intermediary nodes 
> 5 bytes will achieve the desired result of both {letters, numbers, control characters}
> i chose 5 for simplicity as in being able to use a well working hand to encode messages
> as is recommended the leftmost bit {e || t} will be designated as the thumb as this already has two joints
> essentially i was just going for reducing the bits needed to write programs and morph that into morse code
>
> as much as i hate to admit it some of the characters do not exist in the computer
> as indicated below there are some symbols i do not like particularly however i understand the need
> i will use them as there is an abundance of the value of these symbols
> 
> do not quote the examples or uppercase symbols, they are subject to change
> the only relative positions of the initial 8 bit subset are shown below
>
> 26

## control characters

> these characters are the essentials for abstracted and recursive programming
> it is the best set of commonly used characters i was able to fit into 5 bytes

## short examples, with some sugar added

```
*                       (wildcard representing some shit going on i am too lazy to annotate)
100$40                  (one hundred and fourty cents)
apples \ oranges        (apples or oranges, written, reasoning is in set logic \ continuance is \/ or or)
apples / oranges        (apples and oranges, written, same mathematical set logic / becomes /\ which is and)
**                      (exponent, this stays for now, it's a good idea, big fan of this)
_(*)                    (lowkey some fuckery going on in this control structure, usually mathematics)
/ beans                 (a comment)
```
## character groups

```
> L = new line
> D = end of file, data, etc
> # = metadata designator (e.g. mom#000-000-0000, work#(XX Street), instagram#(username))
> S = space
> 
> note: the symbology i use is quite different however it does not exist yet

  0 1 2 3 4 5 6 7 8 9 a b c 
0 [ ] { } ( ) < > / \ ! = |  
1 + - : ; # D ? . , * S L _  
```
## character derivation breakdown

```
e(0) - i(00) - s(000) - h(0000) - 5(00000)
                                - 4(00001)
                      - v(0001) - \(00010)
                                - 3(00011)
             - u(001) - f(0010) - ((00100) 
                                - )(00101)
                      - ?(0011) - _(00110)
                                - 2(00111)
     - a(01) - r(010) - l(0100) - L(01000)
                                - /(01001)
                      - =(0101) - <(01010)
                                - >(01011)
             - w(011) - p(0110) - :(01100)
                                - ;(01101)
                      - j(0111) - |(01110)
                                - 1(01111)
t(1) - n(10) - d(100) - b(1000) - 6(10000)
                                - ,(10001) 
                      - x(1001) - +(10010)
                                - -(10011)
             - k(101) - c(1010) - {(10100)
                                - }(10101)
                      - y(1011) - #(10110)
                                - D(10111)
     - m(11) - g(110) - z(1100) - 7(11000)
                                - !(11001) 
                      - q(1101) - [(11010)
                                - ](11011)  (qq = empty set, written, meme)
             - o(111) - *(1110) - 8(11100)
                                - .(11101)
                      - S(1111) - 9(11110)
                                - 0(11111)
```

## subgrouped tattoo

```
> s = terminal sigma
> h = lowercase phlank constant
> v = scripted reverse v
> 1 = chinese symbol 1/2 work, rotated 90* represents |-| e.g. zuo
> a = alpha
> l = lambda
> L = escape character for newlines 
> w = lowercase omega
> q = replaced pirate symbol with russian (x-esq zh) character, more portable and leaves the wildcard asterix in place
> j = scripted j 
> d = lowercase delta
> y = hawking radiation notation useful for designating 70 with slight curve
> D = symbol for science
> g = laotian inspired symbol designating the english letter g
> S = african warrior shield and spears combination 
> 0 = astrological symbol for the sun, otherwise it's a do not disturb looking thing
> e = reverse inclusion symbol, similar to cyrillic alphabet
> 4 = four, death
> d = phonetic alphabet lowercase del[ta] symbol
> b = soft russian b symbol
> r = looped r symbol to remove the spelling for race involved in past, essentially a clean slate
> ! = horozontal bar followed by immediately connected down tick to denote negation
> note: most lowercase letters excluding (b) are intentionally left scripted for recognition purposes and style

e(i(s(h(5|4)|v(\|3))|u(f((|))|?(_|2)))
  a(r(l(L|/)|=(<|>))|w(p(:|;)|j(||1))))
t(n(d(b(6|,)|x(+|-))|k(c({|})|y( |D)))
  m(g(z(7|!)|q([|]))|o(*(8|.)|S(9|0))))
```

```

e(i(s(h(5|4)|v(\|3))|u(f((|))|?(_|2)))
  a(r(l(L|/)|=(<|>))|w(p(:|;)|j(||1))))
t(n(d(b(6|,)|x(+|-))|k(c({|})|y( |D)))
  m(g(z(7|!)|q([|]))|o(*(8|.)|S(9|0))))
```
