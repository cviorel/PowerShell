<#
.SYNOPSIS
Retrieves a random message of the day.

.DESCRIPTION
The Get-MessageOfTheDay function retrieves a random message of the day from a predefined list of messages. Each time the function is called, it returns a different message.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
PS C:\> Get-MessageOfTheDay
Returns a random message of the day.

.OUTPUTS
System.String
The function returns a string representing the random message of the day.

.NOTES
Author: Viorel Ciucu
Date: 2021-09-01
#>
function Get-MessageOfTheDay {
    $msg = @"
If life gives you lemons, squirt someone in the eye. 😂
Doing nothing is hard; you never know when you're done. 🤣
I'm not lazy, just very relaxed. 😜
Always remember you're unique, just like everyone else. 🙈
I'm not clumsy, it's just the floor hates me, the tables and chairs are bullies, and the wall gets in the way. 😉
Life is short. If you can't laugh at yourself, call me...I'll laugh at you. 😅
To be old and wise, you must first be young and stupid. 🤪
I'm not arguing, I'm simply explaining why I'm right. 🤔
With great power comes an even greater electricity bill. 😇
Money talks...but all mine ever says is goodbye. 😍
I would lose weight, but I hate losing. 🥳
If you think nothing is impossible, try slamming a revolving door. 😎
I'd agree with you but then we'd both be wrong. 👻
My wallet is like an onion, opening it makes me cry. 💩
I didn't fall, I'm just spending some quality time with the floor. 👽
I'm not addicted to reading, I can quit as soon as I finish one more chapter. 🤖
Why is 'abbreviation' such a long word? 🎃
I'm an excellent housekeeper. Every time I get a divorce, I keep the house. 😺
I used to think I was indecisive, but now I'm not too sure. 🦄
My imaginary friend thinks he has problems. 🐉
I'm not short, I'm just more down to earth than other people. 🍀
I'm so good at sleeping, I can do it with my eyes closed. 🌈
If I won the award for laziness, I would send someone to pick it up for me. ⚡
Some days, the best thing about my job is that the chair spins. 🍉
I'm not bossy, I just know exactly what you should be doing. 🍔
I'm not weird, I'm a limited edition. 🍕
I'm not arguing, I'm simply trying to explain why I'm right. 🍺
If life gives you lemons, squirt someone in the eye. 🎮
Doing nothing is hard; you never know when you're done. 🚀
I'm not lazy, just very relaxed. 💡
Always remember you're unique, just like everyone else. 🎁
I'm not clumsy, it's just the floor hates me, the tables and chairs are bullies, and the wall gets in the way. 💰
Life is short. If you can't laugh at yourself, call me...I'll laugh at you. 🧭
To be old and wise, you must first be young and stupid. 🧲
I'm not arguing, I'm simply explaining why I'm right. 🔮
With great power comes an even greater electricity bill. 🛸
Money talks...but all mine ever says is goodbye. 🧨
I would lose weight, but I hate losing. 🔒
If you think nothing is impossible, try slamming a revolving door. 🔑
I'd agree with you but then we'd both be wrong. 🕰
My wallet is like an onion, opening it makes me cry. 🌙
I didn't fall, I'm just spending some quality time with the floor. 🌟
I'm not addicted to reading, I can quit as soon as I finish one more chapter. 🌍
Why is 'abbreviation' such a long word? 🌹
I'm an excellent housekeeper. Every time I get a divorce, I keep the house. 🍄
I used to think I was indecisive, but now I'm not too sure. 🌻
My imaginary friend thinks he has problems. 🌊
I'm not short, I'm just more down to earth than other people. ⛄
If you can't live without me, why aren't you dead yet? 🔥
I'm so good at sleeping, I can do it with my eyes closed. 🎈
If I won the award for laziness, I would send someone to pick it up for me. 🧸
Some days, the best thing about my job is that the chair spins. 📚
I'm not bossy, I just know exactly what you should be doing. 🔔
I'm not weird, I'm a limited edition. 🎧
I'm not arguing, I'm simply trying to explain why I'm right. 🎤
If life gives you lemons, squirt someone in the eye. 🎵
Doing nothing is hard; you never know when you're done. 🍿
I'm not lazy, just very relaxed. 🍫
Always remember you're unique, just like everyone else. 🥑
I'm not clumsy, it's just the floor hates me, the tables and chairs are bullies, and the wall gets in the way. 🍓
Life is short. If you can't laugh at yourself, call me...I'll laugh at you. 🏀
To be old and wise, you must first be young and stupid. 🚗
I'm not arguing, I'm simply explaining why I'm right. ✈️
With great power comes an even greater electricity bill. 🚤
Money talks...but all mine ever says is goodbye. 🛁
I would lose weight, but I hate losing. 🏖
If you think nothing is impossible, try slamming a revolving door. ⛺
I'd agree with you but then we'd both be wrong. 🏰
My wallet is like an onion, opening it makes me cry. 🛡
I didn't fall, I'm just spending some quality time with the floor. 🔑
I'm not addicted to reading, I can quit as soon as I finish one more chapter. 🎨
Why is 'abbreviation' such a long word? 🧵
I'm an excellent housekeeper. Every time I get a divorce, I keep the house. 🧶
I used to think I was indecisive, but now I'm not too sure. 📸
My imaginary friend thinks he has problems. 🔍
I'm not short, I'm just more down to earth than other people. 🚀
If you can't live without me, why aren't you dead yet? 🌵
I'm so good at sleeping, I can do it with my eyes closed. 🎂
If I won the award for laziness, I would send someone to pick it up for me. 🏆
Some days, the best thing about my job is that the chair spins. 🍦
I'm not bossy, I just know exactly what you should be doing. 🍭
I'm not weird, I'm a limited edition. 🍬
I'm not arguing, I'm simply trying to explain why I'm right. 🥥
If life gives you lemons, squirt someone in the eye. 🍍
Doing nothing is hard; you never know when you're done. 🥦
I'm not lazy, just very relaxed. 🍳
Always remember you're unique, just like everyone else. 🥖
I'm not clumsy, it's just the floor hates me, the tables and chairs are bullies, and the wall gets in the way. 🧀
Life is short. If you can't laugh at yourself, call me...I'll laugh at you. 🍷
To be old and wise, you must first be young and stupid. 🍹
I'm not arguing, I'm simply explaining why I'm right. 🥃
With great power comes an even greater electricity bill. 🍻
Money talks...but all mine ever says is goodbye. 🧉
I would lose weight, but I hate losing. 🎱
If you think nothing is impossible, try slamming a revolving door. 🛴
I'd agree with you but then we'd both be wrong. 🎡
My wallet is like an onion, opening it makes me cry. 🎢
I didn't fall, I'm just spending some quality time with the floor. 🎠
I'm not addicted to reading, I can quit as soon as I finish one more chapter. 🏂
Why don't scientists trust atoms? Because they make up everything! 😄
I'm reading a book about anti-gravity. It's impossible to put down! 📚
Why did the scarecrow win an award? Because he was outstanding in his field! 🌾
Why don't skeletons fight each other? They don't have the guts! 💀
I used to be a baker, but I couldn't make enough dough. 🥖
Why did the bicycle fall over? Because it was two-tired! 🚲
What do you call a bear with no teeth? A gummy bear! 🐻
Why did the tomato turn red? Because it saw the salad dressing! 🍅
I'm on a seafood diet. I see food and I eat it! 🍣
Why don't eggs tell jokes? Because they might crack up! 🥚

"@
    $lines = $msg -split "`n"
    $randomLine = $lines | Get-Random
    [Environment]::NewLine + $randomLine + [Environment]::NewLine
}
