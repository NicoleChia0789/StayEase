<section class="search-wrap" aria-label="Search for a homestay">
  <form class="search-bar" action="" method="get">
    <input type="hidden" name="page" value="stays">
    <label class="home-search-field"><span>WHERE</span><div class="search-input-row"><i aria-hidden="true">⌖</i><input name="q" placeholder="Langkawi, Malaysia" value="<?=esc($search)?>" aria-label="Destination or homestay"></div></label>
    <label class="home-search-field"><span>CHECK IN</span><input type="date" name="check_in" min="<?=date('Y-m-d')?>" value="<?=esc($checkIn)?>"></label>
    <label class="home-search-field"><span>CHECK OUT</span><input type="date" name="check_out" min="<?=date('Y-m-d',strtotime('+1 day'))?>" value="<?=esc($checkOut)?>"></label>
    <label class="home-search-field guests-field"><span>GUESTS</span><div class="search-input-row"><i aria-hidden="true">♙</i><select name="guests" aria-label="Number of guests"><?php for($guest=1;$guest<=8;$guest++):?><option value="<?=$guest?>" <?=((int)($_GET['guests']??2)===$guest)?'selected':''?>><?=$guest?> guest<?=$guest===1?'':'s'?></option><?php endfor;?></select></div></label>
    <button class="button button-amber search-submit" type="submit">Search <span aria-hidden="true">⌕</span></button>
  </form>
</section>
