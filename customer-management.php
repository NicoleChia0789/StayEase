<?php
if (!current_user() || current_user()['role']!=='Staff') {
    flash('Sign in with a staff account to manage customers.','error');
    go('?page=login');
}
$pdo=db();
$customerId=(int)($_GET['id']??0);
$customer=null;
$customerBookings=[];
if ($pdo && $page==='customer-detail' && $customerId>0) {
    $q=$pdo->prepare("SELECT user_id,full_name,email,phone,status,created_at,updated_at FROM users WHERE user_id=? AND role='User'");
    $q->execute([$customerId]); $customer=$q->fetch() ?: null;
    if ($customer) {
        $q=$pdo->prepare('SELECT b.booking_id,b.check_in,b.check_out,b.total_price,b.status,h.name homestay FROM bookings b JOIN homestays h ON h.homestay_id=b.homestay_id WHERE b.user_id=? ORDER BY b.created_at DESC');
        $q->execute([$customerId]); $customerBookings=$q->fetchAll();
    }
}
if ($page==='customers') {
    $query=trim($_GET['q']??''); $status=$_GET['status']??'';
    $customers=[]; $counts=['all'=>0,'Active'=>0,'Inactive'=>0];
    if ($pdo) {
        $counts['all']=(int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='User'")->fetchColumn();
        foreach(['Active','Inactive'] as $state){$s=$pdo->prepare("SELECT COUNT(*) FROM users WHERE role='User' AND status=?");$s->execute([$state]);$counts[$state]=(int)$s->fetchColumn();}
        $sql="SELECT u.user_id,u.full_name,u.email,u.phone,u.status,u.created_at,COUNT(b.booking_id) bookings FROM users u LEFT JOIN bookings b ON b.user_id=u.user_id WHERE u.role='User'";
        $params=[];
        if ($query!=='') {$sql.=' AND (u.full_name LIKE ? OR u.email LIKE ? OR u.phone LIKE ?)';$like='%'.$query.'%';$params=[$like,$like,$like];}
        if (in_array($status,['Active','Inactive'],true)) {$sql.=' AND u.status=?';$params[]=$status;}
        $sql.=' GROUP BY u.user_id ORDER BY u.created_at DESC LIMIT 100';
        $s=$pdo->prepare($sql);$s->execute($params);$customers=$s->fetchAll();
    }
    ?>
    <main class="module-page">
      <div class="mock-breadcrumb"><a href="?page=admin">Admin</a> / Customer Management</div>
      <div class="screen-title"><div><span class="eyebrow">CUSTOMER MANAGEMENT</span><h1>Customer directory</h1><p>Search accounts, update customer details and preserve their booking history.</p></div><a class="mock-button primary" href="?page=customer-form">＋ Register customer</a></div>
      <?php if(!$pdo): ?><div class="availability-note">Customer records are unavailable because StayEase could not connect to MySQL. Start the XAMPP MySQL service and import <code>database/stayease.sql</code>.</div><?php else: ?>
      <div class="metric-row"><div><small>TOTAL CUSTOMERS</small><b><?= $counts['all'] ?></b><span>Customer accounts</span></div><div><small>ACTIVE</small><b><?= $counts['Active'] ?></b><span>Can sign in and book</span></div><div><small>INACTIVE</small><b><?= $counts['Inactive'] ?></b><span>History retained</span></div></div>
      <section class="mock-panel"><form class="toolbar-row" method="get"><input type="hidden" name="page" value="customers"><div class="mock-search">⌕ <input name="q" value="<?= esc($query) ?>" placeholder="Search name, email or phone"></div><select name="status"><option value="">All account statuses</option><option value="Active" <?= $status==='Active'?'selected':'' ?>>Active</option><option value="Inactive" <?= $status==='Inactive'?'selected':'' ?>>Inactive</option></select><button class="mock-button outline">Search</button></form>
        <div class="mock-table-wrap"><table class="mock-table"><thead><tr><th>CUSTOMER</th><th>EMAIL</th><th>PHONE</th><th>BOOKINGS</th><th>STATUS</th><th>ACTION</th></tr></thead><tbody>
        <?php foreach($customers as $row): ?><tr><td><?= esc($row['full_name']) ?><small class="table-subtext">ID #<?= (int)$row['user_id'] ?></small></td><td><?= esc($row['email']) ?></td><td><?= esc($row['phone']) ?></td><td><?= (int)$row['bookings'] ?></td><td><span class="pill <?= $row['status']==='Active'?'active':'inactive' ?>"><?= esc($row['status']) ?></span></td><td><a class="text-link" href="?page=customer-detail&id=<?= (int)$row['user_id'] ?>">View / edit →</a></td></tr><?php endforeach; ?>
        <?php if(!$customers): ?><tr><td colspan="6">No customer accounts match this search.</td></tr><?php endif; ?>
        </tbody></table></div><p class="admin-note">Showing up to 100 matching customer accounts. Account status changes never delete booking records.</p>
      </section><?php endif; ?>
    </main><?php
} elseif ($page==='customer-form') { ?>
    <main class="module-page"><div class="mock-breadcrumb"><a href="?page=customers">Customers</a> / Register customer</div><div class="screen-title"><div><span class="eyebrow">CUSTOMER MANAGEMENT</span><h1>Register a customer</h1><p>Staff can create an account for a walk-in or phone guest. Staff accounts are predefined separately.</p></div></div>
      <?php if(!$pdo): ?><div class="availability-note">The database is unavailable. Start XAMPP MySQL before creating an account.</div><?php else: ?>
      <form class="mock-panel form-narrow customer-form" method="post"><input type="hidden" name="action" value="create_customer"><div class="panel-heading"><div><h2>Customer information</h2><p>All fields are required. The email address must be unique.</p></div><span class="pill active">Role: Customer</span></div>
        <label class="mock-field"><span>FULL NAME *</span><input name="full_name" maxlength="100" autocomplete="name" required></label><label class="mock-field"><span>EMAIL ADDRESS *</span><input type="email" name="email" maxlength="100" autocomplete="email" required></label><label class="mock-field"><span>PHONE NUMBER *</span><input name="phone" maxlength="20" autocomplete="tel" required></label><label class="mock-field"><span>TEMPORARY PASSWORD *</span><input type="password" name="password" minlength="8" autocomplete="new-password" required><small>At least 8 characters. Give it to the customer privately.</small></label>
        <div class="panel-actions"><button class="mock-button primary" type="submit">Create customer account</button><a class="mock-button outline" href="?page=customers">Cancel</a></div>
      </form><?php endif; ?>
    </main>
<?php } elseif ($page==='customer-detail') { ?>
    <main class="module-page"><div class="mock-breadcrumb"><a href="?page=customers">Customers</a> / Customer details</div>
    <?php if(!$customer): ?><div class="empty-state"><h2>Customer account not found</h2><a class="button button-dark" href="?page=customers">Return to customer directory</a></div>
    <?php else: ?><div class="screen-title"><div><span class="eyebrow">CUSTOMER MANAGEMENT</span><h1>Customer profile</h1><p>Review and update the account. Booking history remains linked to this customer.</p></div><span class="pill <?= $customer['status']==='Active'?'active':'inactive' ?>"><?= esc($customer['status']) ?> account</span></div>
      <div class="two-panels"><form class="mock-panel customer-form" method="post"><input type="hidden" name="action" value="update_customer"><input type="hidden" name="user_id" value="<?= (int)$customer['user_id'] ?>"><h2>Contact information</h2><label class="mock-field"><span>FULL NAME</span><input name="full_name" maxlength="100" value="<?= esc($customer['full_name']) ?>" required></label><label class="mock-field"><span>EMAIL</span><input type="email" name="email" maxlength="100" value="<?= esc($customer['email']) ?>" required></label><label class="mock-field"><span>PHONE</span><input name="phone" maxlength="20" value="<?= esc($customer['phone']) ?>" required></label><p class="admin-note">Joined <?= esc(date('j M Y',strtotime($customer['created_at']))) ?> · Customer ID #<?= (int)$customer['user_id'] ?></p><button class="mock-button primary" type="submit">Save customer details</button></form>
        <section class="mock-panel"><h2>Account status</h2><p><?= $customer['status']==='Active'?'This customer can sign in and make bookings.':'This customer cannot sign in while the account is inactive.' ?></p><form method="post"><input type="hidden" name="action" value="toggle_customer_status"><input type="hidden" name="user_id" value="<?= (int)$customer['user_id'] ?>"><input type="hidden" name="status" value="<?= $customer['status']==='Active'?'Inactive':'Active' ?>"><button class="mock-button <?= $customer['status']==='Active'?'outline':'primary' ?>" type="submit"><?= $customer['status']==='Active'?'Deactivate account':'Reactivate account' ?></button></form><p class="admin-note">Deactivation preserves the account and all linked bookings.</p></section></div>
      <section class="mock-panel spaced"><div class="panel-heading"><div><h2>Booking history</h2><p><?= count($customerBookings) ?> linked booking<?= count($customerBookings)===1?'':'s' ?></p></div></div><div class="mock-table-wrap"><table class="mock-table"><thead><tr><th>BOOKING</th><th>HOMESTAY</th><th>DATES</th><th>TOTAL</th><th>STATUS</th></tr></thead><tbody><?php foreach($customerBookings as $booking): ?><tr><td>#<?= (int)$booking['booking_id'] ?></td><td><?= esc($booking['homestay']) ?></td><td><?= esc(date('j M Y',strtotime($booking['check_in']))) ?> – <?= esc(date('j M Y',strtotime($booking['check_out']))) ?></td><td><?= money($booking['total_price']) ?></td><td><?= esc($booking['status']) ?></td></tr><?php endforeach; ?><?php if(!$customerBookings): ?><tr><td colspan="5">No bookings are linked to this customer yet.</td></tr><?php endif; ?></tbody></table></div></section>
    <?php endif; ?></main>
<?php } ?>
