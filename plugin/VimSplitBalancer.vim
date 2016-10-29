" VimSplitBalancer.vim:
" Maintainer:   jordwalke <github.com/jordwalke>
" License:      MIT
"
" =============================VimSplitBalancer.vim==============================
" Distributes available space among vertical splits, but plays nice with
" NERDTree.
"
" The currently focused vertical split will always automatically be resized
" according to the max amount of characters horizontally in that text file.
" The remaining space will be evenly distributed across all of the other
" vertical splits.
"
"  Load Once:
if &cp || exists( 'g:vim_split_balancer' )
    finish
endif

let g:NERDSideBarSize=35
let g:NERDSideBarSplitMax=110
let g:NERDSideBarSplitMin=70
let g:vim_split_balancer = 1


" There's got to be a builtin for this!
function s:Min(num1, num2)
  if a:num1 < a:num2
    return a:num1
  endif
  return a:num2
endfunction

function s:Max(num1, num2)
  if a:num1 > a:num2
    return a:num1
  endif
  return a:num2
endfunction

" FROM: http://stackoverflow.com/questions/9148919/how-to-resize-a-window-to-fit-taking-into-account-only-logical-lines
fu! s:Sum(vals)
    let acc = 0
    for val in a:vals
        let acc += val
    endfor
    return acc
  endfu
fu! s:LogicalLineCounts()
    if &wrap
        let width = winwidth(0)
        let line_counts = map(range(1, line('$')), "foldclosed(v:val)==v:val?1:(virtcol([v:val, '$'])/width)+1")
    else
        let line_counts = [line('$')]
    endif
    return line_counts
endfu
fu! s:LinesHiddenByFoldsCount()
    let lines = range(1, line('$'))
    call filter(lines, "foldclosed(v:val) > 0 && foldclosed(v:val) != v:val")
    return len(lines)
endfu 

fu! s:AutoResizeWindow(vert)
    if a:vert
        let longest = max(map(range(1, line('$')), "virtcol([v:val, '$'])"))
        exec "set winwidth=" . s:Max(g:NERDSideBarSplitMin, s:Min(longest, g:NERDSideBarSplitMax))
    else
        let line_counts  = s:LogicalLineCounts()
        let folded_lines = s:LinesHiddenByFoldsCount()
        let lines        = s:Sum(line_counts) - folded_lines
        exec 'resize ' . lines
        1
    endif
endfu


" Works when the sidebar is open
function! s:EnsureNERDWidth()
  let shouldResize = exists("g:VimSplitBalancerSupress") && g:VimSplitBalancerSupress != 1 || !exists("g:VimSplitBalancerSupress")
  if shouldResize
    "echo "ENSURING ".winnr()
    if winnr() == 1
      " close enough
      if (exists("b:NERDTreeType"))
        set winwidth=1
        "execute "NERDTreeClose"
        wincmd =
        "execute "NERDTree"
        execute "vertical resize ".g:NERDSideBarSize
        wincmd =
      else
        call s:AutoResizeWindow(1)
        wincmd =
      endif
    else
      call s:AutoResizeWindow(1)
      " Jump to window one, see if it's a NERDTree then resize it if so.
      wincmd t
      let sideBarIsOpen = exists("b:NERDTreeType") ? 1 : 0
      wincmd p  "then jump back to where we were

      " Now we know if its open
      if sideBarIsOpen
        wincmd t
        execute "vertical resize ".g:NERDSideBarSize
        wincmd p
        wincmd =
      else
        wincmd =
      endif
    endif
  endif
endfunction

function! s:EnsureEqual()
  wincmd =
endfunction

if has("gui_running")
  " Listens for WinResize events and store the last observed NERDTree width (win
  " 1) in b:nerdWith - then restore that instead of 40!
  " See help: 'Moving cursor to other windows			*window-move-cursor*'
  let g:NERDTreeWinSize=35
  " Dillgently remember the sidebar size
  " autocmd TabLeave   * call <SID>CaptureNERDWidth()
  " autocmd WinLeave   * call <SID>CaptureNERDWidth()

  " Restore it.
  autocmd VimResized * call <SID>EnsureNERDWidth()
  autocmd BufEnter   * call <SID>EnsureNERDWidth()
  " Not sure why we needed this `WinEnter` hook, and it messed up
  " the special "HUD" style location list layers in VimBox.
  " autocmd WinEnter   * call <SID>EnsureEqual()
  autocmd TabEnter   * call <SID>EnsureNERDWidth()
endif
