<?php
class user extends CI_Model {

	var $logged_in;
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

	public validate($logged_in = FALSE)
	{
		if($logged_in === FALSE)
		{
			$account = $this->session->all_userdata();
		}
		else {
			prompt_login();
			$newdata = array(
                   'username'  => $user,
                   'email'     => $email,
                   'password'  => $pass,
                   'logged_in' => TRUE
               );

            $this->session->set_userdata($newdata);
        }
	}
	
	public function prompt_login()
	{
		
	}
	
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
	
}
