document.addEventListener('DOMContentLoaded',()=>{
  const menu=document.querySelector('.menu-toggle');
  const nav=document.querySelector('.main-nav');
  const closeMenu=()=>{
    nav?.classList.remove('open');
    menu?.setAttribute('aria-expanded','false');
  };
  menu?.addEventListener('click',()=>{
    const open=nav?.classList.toggle('open')??false;
    menu.setAttribute('aria-expanded',String(open));
  });
  nav?.querySelectorAll('a').forEach(link=>link.addEventListener('click',closeMenu));
  document.addEventListener('keydown',event=>{if(event.key==='Escape')closeMenu();});
  document.addEventListener('click',event=>{
    if(nav?.classList.contains('open')&&!nav.contains(event.target)&&!menu?.contains(event.target))closeMenu();
  });

  const nextDate=value=>{
    if(!/^\d{4}-\d{2}-\d{2}$/.test(value))return '';
    const [year,month,day]=value.split('-').map(Number);
    const date=new Date(Date.UTC(year,month-1,day+1));
    return `${date.getUTCFullYear()}-${String(date.getUTCMonth()+1).padStart(2,'0')}-${String(date.getUTCDate()).padStart(2,'0')}`;
  };
  document.querySelectorAll('form').forEach(form=>{
    const checkin=form.querySelector('[name="check_in"]');
    const checkout=form.querySelector('[name="check_out"]');
    if(!checkin||!checkout)return;
    const updateDates=()=>{
      const minimum=nextDate(checkin.value);
      if(minimum)checkout.min=minimum;
      checkout.setCustomValidity(checkout.value&&minimum&&checkout.value<minimum?'Check-out must be at least one day after check-in.':'');
    };
    checkin.addEventListener('input',updateDates);
    checkin.addEventListener('change',updateDates);
    checkout.addEventListener('input',updateDates);
    checkout.addEventListener('change',updateDates);
    form.addEventListener('submit',event=>{
      updateDates();
      if(!form.checkValidity()){event.preventDefault();form.reportValidity();}
    });
    updateDates();
  });

  const savedKey='stayease:saved-stays';
  let saved=[];
  try{saved=JSON.parse(localStorage.getItem(savedKey)||'[]');if(!Array.isArray(saved))saved=[];}catch{saved=[];}
  const saveButtons=document.querySelectorAll('.heart[data-stay-id]');
  const updateSaveButton=(button,isSaved)=>{
    const name=button.closest('.stay-card')?.querySelector('h3')?.textContent?.trim()||'stay';
    button.classList.toggle('saved',isSaved);
    button.setAttribute('aria-pressed',String(isSaved));
    button.setAttribute('aria-label',`${isSaved?'Remove':'Add'} ${name} ${isSaved?'from':'to'} saved stays`);
    button.textContent=isSaved?'♥':'♡';
    button.title=isSaved?'Remove from saved stays':'Save this stay';
  };
  saveButtons.forEach(button=>{
    const id=button.dataset.stayId;
    updateSaveButton(button,saved.includes(id));
    button.addEventListener('click',event=>{
      event.preventDefault();event.stopPropagation();
      saved=saved.includes(id)?saved.filter(item=>item!==id):[...saved,id];
      try{localStorage.setItem(savedKey,JSON.stringify(saved));}catch{}
      updateSaveButton(button,saved.includes(id));
    });
  });

  const grid=document.querySelector('.edit-grid');
  document.querySelectorAll('.edit-controls [data-direction]').forEach(button=>button.addEventListener('click',()=>{
    if(!grid||grid.children.length<2)return;
    const direction=button.dataset.direction;
    grid.classList.add('is-shifting');
    window.setTimeout(()=>{
      if(direction==='previous')grid.append(grid.lastElementChild);
      else grid.prepend(grid.firstElementChild);
      grid.classList.remove('is-shifting');
      grid.setAttribute('aria-label',`Featured stays carousel, showing ${grid.children.length} stays`);
    },160);
  }));

  const revealItems=document.querySelectorAll('.reveal');
  const reduceMotion=window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if(reduceMotion||!('IntersectionObserver' in window)){
    revealItems.forEach(item=>item.classList.add('is-visible'));
  }else{
    document.body.classList.add('motion-ready');
    const observer=new IntersectionObserver(entries=>entries.forEach(entry=>{
      if(entry.isIntersecting){entry.target.classList.add('is-visible');observer.unobserve(entry.target);}
    }),{threshold:.12,rootMargin:'0px 0px -36px 0px'});
    revealItems.forEach(item=>observer.observe(item));
  }

  const toast=document.querySelector('.toast');
  if(toast)setTimeout(()=>toast.remove(),5200);
});
