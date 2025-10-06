# dnf-notify
This Ansbile Playbook does the following:

1) Installs dnf-automatic
2) Copies the automatic.conf from roles/rhel_update_notify/files to /etc/dnf/
3) Restarts dnf-automatic
4) Installs dnf-report.sh script from roles/rhel_update_notify/files to /usr/local/bin/ and makes it executable
5) Enables dnf timers

NOTE: You must add a webhook in dnf-report.sh

Run using this command ansible-playbook -i <host>, playbooks/notify.yml -b