Working through horsefacts' article!
The code is so elegant!
https://mirror.xyz/horsefacts.eth/Jex2YVaO65dda6zEyfM_-DXlXhOWCAoSpOx5PLocYgw
https://github.com/horsefacts/weth-invariant-testing

Things I learned:

1. What is invariant testing?
2. Open testing && Testing by handler
3. Elegant coding style about ghost variables and actors
4. How to iterate the handler to test more efficiently?

Some notes:

1. Learning to read failed call sequences is part of the art of invariant testing. One important clue is that the last call in the sequence should always be the one that caused the invariant to fail.
2. If any of our assumptions are wrong in both the contract under test and in our ghost variable logic that replicates it, we will simply be replicating bugs in the implementation in our tests. In general, I think it's a good principle to rely on external state from the contract under test whenever possible.
3. Alaways be careful with your assumptions about testing!
