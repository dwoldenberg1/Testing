<?php
class user extends CI_Model {

	var $logged_in=FALSE;
	private var $user;
	private var $pass;
	private var $email;
	private final var $account;
	
	//$this->session->sess_destroy();=logout
	//http://ellislab.com/codeigniter/user-guide/libraries/sessions.html

	public function __construct()
	{
		$account=[$user, $pass, $email];
		
		
	}

	public function index()
	{
		echo 'index';
	}
	
	public function create_acccount()
	{
		$this->load->helper('url');

		$user = url_title($this->input->post('user'), '_', TRUE);

		$data = array(
			'user' => $user,
			'pass' => $this->input->post('pass'),
			'email' =>$this->input->post('email'),
			);

		return $this->db->insert('accounts', $data);
	}

	public function setAccount($data)
	{
        $this->session->set_userdata($data);
	}

	//getter methods
	
	public function get_user($user = FALSE)
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('username' => $user));
		return $query->row()->'username';
		
	}

	public function get_pass()
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('password_encrypted' => $pass));
		return $query->row()->'password_encrypted';
	}

	public function get_email()
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('email' => $email));
		return $query->row()->'email';
	}

	public function isLoggedIn(){
		return $loggen_in;
	}
	
}
