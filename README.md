HAML with CoffeeScript Logic
============================

Project purpose: see the title.

Testing:

    coffee test.coffee
    
of better

    coffee test.coffee | haml

API
----------------------

_see `test.coffee`_

    hsc = require('./hsc')
    hp = HscProcessor 'test.haml'
    hp.render(x: 1)    


What works
----------

### Dash-blocks work with any CS code.

Context vriables are accessible through the single global `c` (context) object.

#### Example:

_Renering with context variable x = 1_

     %body
       - y = 5
       - if c.x + y == 6
         %strong OK

is rendered to 

     %body
       %strong OK


### Equal-blocks work with any CS expression.

#### Example:

_Renering with context variable x = 1_

     %body
       - y = 5
       %em
         = c.x + y

is rendered to

    %body
      %em
        6

### String interpolation, like

    %div
      = "A value of x is #{c.x}"

or

    #div(class="#{if c.x > 7 then 'big' else 'small'}")

### Built-in `:coffee` filter

#### Example 
  
    :coffee
      y = 9
      alert y

should be rendered

    :javascript
      (function() {
        var y;
        v = 9;
        alert(y);
      }).call(this);

This also supports interpolation of the global context variables: 

    :coffee
      c = x: 2
      alert c.x + #{c.x}

should be rendered _(with context variable x = 2)_ to

    :javascript
      (function() {
        var c;
        c = {
          x: 1
        };
        alert(c.x + 2);
      }).call(this);

What doesn't work
-----------------

### Equal-inlines, like

    %strong= c.x

which must be rendered to 

    %strong 5

