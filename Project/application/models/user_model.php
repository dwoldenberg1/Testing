<?php
class user extends CI_Model {

	var $loggedin;
	private var user;
	private var pass;
	private var email;
	private final var account;

	public function __construct()
	{
		account=[user, pass, email];
		
		
	}

	public validate()
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
		return $query->row_array();
		
	}

	public function get_pass()
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('password_encrypted' => $user));
		return $query->row_array();
	}

	public function get_email()
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('password_encrypted' => $user));
		return $query->row_array();
	}
	
	public function index()
	{
		echo 'moo';
		$data['user'] = array('user' => 'bar', 'text' => 'fuck'); //$this->news_model->get_news();
		$data['pass'] = 'Credentials';

		$this->load->view('templates/header', $data);
		$this->load->view('game/index', $data);
		$this->load->view('templates/footer');
	}
	
	public function create_acccount()
	{
		$this->load->helper('url');

		$user = url_title($this->input->post('title'), '_', TRUE);

		$data = array(
			'user' => $this->input->post('title'),
			'pass' => $slug,
			'text' => $this->input->post('text')
			);

		return $this->db->insert('news', $data);
	}
	
}
