^#+Left::
n := VD.getCurrentDesktopNum()
if n = 1
{
    Return
}
n -= 1
VD.MoveWindowToDesktopNum("A",n), VD.goToDesktopNum(n)
Return

^#+Right::
n := VD.getCurrentDesktopNum()
if n = % VD.getCount()
{
    Return
}
n += 1
VD.MoveWindowToDesktopNum("A",n), VD.goToDesktopNum(n)
Return
