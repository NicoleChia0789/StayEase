<?php
$destinations=array_values(array_unique(array_merge(array_column($all,'state'),array_column($all,'city'))));
sort($destinations);
$facilityOptions=[
  'pool'=>'Swimming pool','wifi'=>'Wi-Fi','beachfront'=>'Beachfront','pet_friendly'=>'Pet-friendly',
  'kitchen'=>'Kitchen','family_friendly'=>'Family-friendly','nature'=>'Nature','city_center'=>'Central location',
  'quiet'=>'Quiet stay','romantic'=>'Romantic stay'
];
?>
<main class="stay-search-page">
  <header class="stay-search-heading">
    <span class="eyebrow">STAYEASE COLLECTION</span>
    <h1>Find your <em>perfect stay.</em></h1>
    <p>Search available homestays by location, dates, guests, budget and facilities.</p>
  </header>
  <form class="homestay-search-panel" method="get" action="">
    <input type="hidden" name="page" value="stays">
    <div class="filter-panel-heading"><div><h2>Search homestays</h2><p>Availability and guest capacity are checked against current records.</p></div><?php if($search||$location||$checkIn||$checkOut||$facilityFilters):?><a class="clear-filters" href="?page=stays">Clear filters</a><?php endif;?></div>
    <div class="homestay-filter-grid">
      <label class="filter-control"><span>LOCATION</span><select name="location"><option value="">All Malaysia</option><?php foreach($destinations as $destination):?><option value="<?=esc($destination)?>" <?=$location===$destination?'selected':''?>><?=esc($destination)?></option><?php endforeach;?></select></label>
      <label class="filter-control"><span>CHECK-IN</span><input type="date" name="check_in" min="<?=date('Y-m-d')?>" value="<?=esc($checkIn)?>"></label>
      <label class="filter-control"><span>CHECK-OUT</span><input type="date" name="check_out" min="<?=date('Y-m-d',strtotime('+1 day'))?>" value="<?=esc($checkOut)?>"></label>
      <label class="filter-control"><span>ADULTS</span><select name="adults"><?php for($n=1;$n<=8;$n++):?><option value="<?=$n?>" <?=$adults===$n?'selected':''?>><?=$n?> adult<?=$n===1?'':'s'?></option><?php endfor;?></select></label>
      <label class="filter-control"><span>CHILDREN</span><select name="children"><?php for($n=0;$n<=8;$n++):?><option value="<?=$n?>" <?=$children===$n?'selected':''?>><?=$n===0?'No children':$n.' child'.($n===1?'':'ren')?></option><?php endfor;?></select></label>
      <label class="filter-control"><span>BUDGET UP TO (RM / NIGHT)</span><select name="budget"><?php foreach([0,300,500,800,1000,1400,2000] as $amount):?><option value="<?=$amount?>" <?=$maxPrice===$amount?'selected':''?>><?=$amount===0?'Any budget':'RM '.number_format($amount)?></option><?php endforeach;?></select></label>
    </div>
    <fieldset class="facility-filter"><legend>FACILITIES & STYLE</legend><div class="facility-options"><?php foreach($facilityOptions as $value=>$label):?><label class="facility-chip"><input type="checkbox" name="facilities[]" value="<?=esc($value)?>" <?=in_array($value,$facilityFilters,true)?'checked':''?>><span><?=esc($label)?></span></label><?php endforeach;?></div></fieldset>
    <div class="search-panel-footer"><p><span aria-hidden="true">✓</span> <?=count($filtered)?> homestay<?=count($filtered)===1?'':'s'?> match your search</p><button class="button button-amber" type="submit"><span aria-hidden="true">⌕</span> Search homestays</button></div>
  </form>
  <section class="stay-results-section"><div class="section-top"><div><span class="eyebrow">THE STAYEASE COLLECTION</span><h2>Available homestays</h2></div><span class="result-count"><?=count($filtered)?> results</span></div><div class="stay-grid listing-grid"><?php foreach($filtered as $s) echo stay_card($s); ?><?php if(!$filtered):?><div class="empty-state"><span>⌕</span><h2>No homestays found</h2><p>Try another location, budget or facility selection.</p><a class="button button-dark" href="?page=stays">Clear filters</a></div><?php endif;?></div></section>
</main>
