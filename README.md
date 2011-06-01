HAML with CoffeeScript Logic
============================

Project purpose: see the name.

Testing:

    coffee hsc.coffee
    
of better

    coffee hsc.coffee | haml

API
----------------------

_(to be exported)_

    hsc = require('./hsc')
    hp = HscProcessor 'test.haml'
    hp.render(x: 1)
    


What works
----------

Dash-blocks work with any CS code.

Context vriables are accessible through the sigle globa `c` object.

### Example:

_Renering with context variable x = 1_

     %body
       - y = 5
       - if x + y == 6
         %strong OK

Equal-blocks work with any CS expression.

### Example:

_Renering with context variable x = 1_

     %body
       - y = 5
       %em
         = x + y

What doesn't work
-----------------

_But planned_

Equal-inlines, like

    %strong= x

String interpolation, like

    %div
      = "A value of x is ${c.x}"

or

    #div(class="if c.x > 7 then 'big' else 'small'")

What else planned
-----------------

Built-in `:coffee` filter with built-in context variables, like

    :coffee
      c = {x: 7}
      y = ${c.x} + c.x
      alert y

should be rendered _(with context variable x = 2)_ to 
(omitting sandbox closure function)

    :javascript
      var c, y;
      c = {x: 7};
      y = 2 + c.x;
      alert(y);