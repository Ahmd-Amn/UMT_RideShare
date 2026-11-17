document.querySelectorAll('[data-confirm]').forEach(form => form.addEventListener('submit', event => {
  if (!confirm(form.dataset.confirm)) event.preventDefault();
}));

document.querySelectorAll('[data-password-toggle]').forEach(button => button.addEventListener('click', () => {
  const input = document.getElementById(button.dataset.passwordToggle);
  const showing = input.type === 'password';
  input.type = showing ? 'text' : 'password';
  button.setAttribute('aria-pressed', String(showing));
  button.setAttribute('aria-label', `${showing ? 'Hide' : 'Show'} ${input.id === 'confirm_password' ? 'password confirmation' : 'password'}`);
}));
