'use strict';
'require view';
'require form';
'require fs';
'require rpc';
'require uci';
'require ui';

var callInitAction = rpc.declare({
	object: 'luci',
	method: 'setInitAction',
	params: [ 'name', 'action' ],
	expect: { result: false }
});

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('singbox_server'),
			fs.exec_direct('/etc/init.d/singbox_server', [ 'enabled' ]).catch(function() { return ''; }),
			fs.exec_direct('/etc/init.d/singbox_server', [ 'running' ]).catch(function() { return ''; })
		]);
	},

	render: function(data) {
		var m, s, o;
		var running = data[2].trim() === 'running';

		m = new form.Map('singbox_server', _('sing-box Server'),
			_('A lightweight sing-box server LuCI frontend.'));

		s = m.section(form.NamedSection, 'config', 'main', _('Status'));
		s.anonymous = true;

		o = s.option(form.DummyValue, '_status', _('Current status'));
		o.rawhtml = true;
		o.cfgvalue = function() {
			return running
				? '<span style="color:green;font-weight:bold">' + _('Running') + '</span>'
				: '<span style="color:red;font-weight:bold">' + _('Stopped') + '</span>';
		};

		o = s.option(form.Button, '_start', _('Start'));
		o.inputstyle = 'apply';
		o.onclick = function() {
			return callInitAction('singbox_server', 'start').then(function() { location.reload(); });
		};

		o = s.option(form.Button, '_stop', _('Stop'));
		o.inputstyle = 'reset';
		o.onclick = function() {
			return callInitAction('singbox_server', 'stop').then(function() { location.reload(); });
		};

		o = s.option(form.Button, '_restart', _('Restart'));
		o.inputstyle = 'reload';
		o.onclick = function() {
			return callInitAction('singbox_server', 'restart').then(function() { location.reload(); });
		};

		s = m.section(form.NamedSection, 'config', 'main', _('Basic settings'));
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = '0';

		o = s.option(form.ListValue, 'protocol', _('Protocol'));
		o.value('vless', 'VLESS');
		o.value('trojan', 'Trojan');
		o.value('shadowsocks', 'Shadowsocks 2022');
		o.default = 'vless';

		o = s.option(form.Value, 'listen', _('Listen address'));
		o.placeholder = '::';
		o.default = '::';

		o = s.option(form.Value, 'port', _('Listen port'));
		o.datatype = 'port';
		o.default = '443';

		o = s.option(form.ListValue, 'log_level', _('Log level'));
		[ 'trace', 'debug', 'info', 'warn', 'error', 'fatal', 'panic' ].forEach(function(v) { o.value(v); });
		o.default = 'info';

		o = s.option(form.Flag, 'sniff', _('Enable sniff'));
		o.default = '1';

		o = s.option(form.Value, 'uuid', _('UUID'));
		o.depends('protocol', 'vless');
		o.placeholder = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

		o = s.option(form.Value, 'password', _('Password'));
		o.password = true;
		o.depends('protocol', 'trojan');
		o.depends('protocol', 'shadowsocks');

		s = m.section(form.NamedSection, 'config', 'main', _('TLS settings'));
		s.anonymous = true;

		o = s.option(form.Flag, 'tls_enabled', _('Enable TLS'));
		o.default = '0';

		o = s.option(form.Value, 'server_name', _('Server name'));
		o.depends('tls_enabled', '1');

		o = s.option(form.Value, 'cert_file', _('Certificate file'));
		o.depends('tls_enabled', '1');
		o.default = '/etc/singbox-server/cert.pem';

		o = s.option(form.Value, 'key_file', _('Private key file'));
		o.depends('tls_enabled', '1');
		o.default = '/etc/singbox-server/key.pem';

		return m.render();
	}
});
